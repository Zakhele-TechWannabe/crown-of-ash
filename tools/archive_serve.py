#!/usr/bin/env python3
"""Index the game's life archive into SQLite and serve the viewer on 127.0.0.1 only.

Usage: python3 tools/archive_serve.py [--archive DIR] [--port 8765] [--index-only]
Standard library only. The archive is written by src/archive.gd; nothing here writes to it.
"""
import argparse
import gzip
import http.server
import json
import os
from pathlib import Path
import sqlite3
import threading
import urllib.parse

HERE = Path(__file__).resolve().parent
VIEWER = HERE.parent / 'docs' / 'archive_viewer.html'
SKILLS = HERE.parent / 'data' / 'skills'
DEFAULT_ARCHIVE = Path(os.environ.get('XDG_DATA_HOME', Path.home() / '.local' / 'share')) / 'godot' / 'app_userdata'
BOND_NAMES = ['friend', 'sworn sibling', 'romance', 'spouse', 'dao companion', 'master', 'disciple', 'rival', 'enemy', 'benefactor', 'debt of grace']

SCHEMA = '''
create table if not exists files(run text, path text, mtime real, primary key(run, path));
create table if not exists runs(run text primary key, meta text);
create table if not exists people(run text, year int, id int, name text, sex int, born int, alive int, home int, job text,
  mother int, father int, spouse int, master int, realm int, layer int, realm_label text, qi real, root text,
  reputation real, mood real, factions text, primary key(run, year, id));
create table if not exists skills(run text, year int, id int, skill text, level int, xp real);
create table if not exists ties(run text, year int, a int, b int, opinion real, trust int, bonds int);
create table if not exists factions(run text, year int, fid int, type text, name text, leader int, size int, members text,
  cohesion real, reputation real, absorbed_into int, primary key(run, year, fid));
create table if not exists events(run text, src text, day int, person int, kind text, text text);
create index if not exists skills_at on skills(run, year, id);
create index if not exists ties_at on ties(run, year, a);
create index if not exists events_at on events(run, day);
create index if not exists events_person on events(run, person);
'''


def find_archive_root(base: Path) -> Path:
    if (base / 'latest.txt').exists():
        return base
    for candidate in sorted(base.glob('*/archive')):
        if (candidate / 'latest.txt').exists():
            return candidate
    raise SystemExit(f'No archive found under {base}; run the game first or pass --archive')


def read_lines(path: Path):
    with gzip.open(path, 'rt', encoding='utf-8') as stream:
        for line in stream:
            if line.strip():
                yield json.loads(line)


def index(db: sqlite3.Connection, archive: Path) -> None:
    for run_dir in sorted(p for p in archive.iterdir() if p.is_dir() and p.name.startswith('run_')):
        run = run_dir.name
        meta = run_dir / 'meta.json'
        if meta.exists():
            db.execute('insert or replace into runs values (?, ?)', (run, meta.read_text()))
        for path in sorted(run_dir.glob('year_*/*.jsonl.gz')):
            rel = str(path.relative_to(run_dir))
            mtime = path.stat().st_mtime
            seen = db.execute('select mtime from files where run=? and path=?', (run, rel)).fetchone()
            if seen and seen[0] == mtime:
                continue
            year = int(path.parent.name.split('_')[1])
            if path.name.startswith('events'):
                db.execute('delete from events where run=? and src=?', (run, rel))
                db.executemany('insert into events values (?,?,?,?,?,?)',
                               ((run, rel, e['day'], e['person'], e['kind'], e['text']) for e in read_lines(path)))
            elif path.name.startswith('people'):
                for table in ('people', 'skills', 'ties'):
                    db.execute(f'delete from {table} where run=? and year=?', (run, year))
                for p in read_lines(path):
                    db.execute('insert into people values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)', (
                        run, year, p['id'], p['name'], p['sex'], p['born'], p['alive'], p['home'], p['job'], p['mother'],
                        p['father'], p['spouse'], p['master'], p['realm'], p['layer'], p['realm_label'], p['qi'], p['root'],
                        p['reputation'], p['mood'], json.dumps(p['factions'])))
                    db.executemany('insert into skills values (?,?,?,?,?,?)', ((run, year, p['id'], s[0], s[1], s[2]) for s in p['skills']))
                    db.executemany('insert into ties values (?,?,?,?,?,?,?)', ((run, year, p['id'], t[0], t[1], t[2], t[3]) for t in p['ties']))
            elif path.name.startswith('factions'):
                db.execute('delete from factions where run=? and year=?', (run, year))
                db.executemany('insert into factions values (?,?,?,?,?,?,?,?,?,?,?)', (
                    (run, year, f['id'], f['type'], f['name'], f['leader'], f['size'], json.dumps(f['members']),
                     f['cohesion'], f['reputation'], f['absorbed_into']) for f in read_lines(path)))
            db.execute('insert or replace into files values (?,?,?)', (run, rel, mtime))
        db.commit()


def skill_names() -> dict:
    """Display names for every skill id, from the game's catalogue: {id: "Domain › Name"}."""
    domains = {d['id']: d['name'] for d in json.loads((SKILLS / 'domains.json').read_text())}
    names = {}

    def walk(node, domain):
        if isinstance(node, dict):
            if isinstance(node.get('id'), str) and isinstance(node.get('name'), str) and '.' in node['id']:
                names[node['id']] = f"{domains.get(domain, domain)} › {node['name']}"
            for value in node.values():
                walk(value, domain)
        elif isinstance(node, list):
            for value in node:
                walk(value, domain)

    for path in sorted((SKILLS / 'domains').glob('*.json')):
        walk(json.loads(path.read_text()), path.stem)
    return names


def bonds(flags: int) -> list:
    return [name for i, name in enumerate(BOND_NAMES) if flags & (1 << i)]


def rows(db, sql, args=()):
    cursor = db.execute(sql, args)
    columns = [c[0] for c in cursor.description]
    return [dict(zip(columns, r)) for r in cursor.fetchall()]


class Api:
    def __init__(self, db_path: Path, archive: Path):
        self.db_path, self.archive, self.lock = db_path, archive, threading.Lock()

    def connect(self):
        db = sqlite3.connect(self.db_path)
        db.executescript(SCHEMA)
        return db

    def refresh(self):
        with self.lock:
            db = self.connect()
            index(db, self.archive)
            db.close()

    def call(self, route: str, q: dict):
        db = self.connect()
        try:
            return getattr(self, 'api_' + route)(db, q)
        finally:
            db.close()

    def latest_year(self, db, run):
        return db.execute('select max(year) from people where run=?', (run,)).fetchone()[0]

    def api_catalogue(self, db, q):
        return {'skills': skill_names()}

    def api_runs(self, db, q):
        self.refresh()
        latest = (self.archive / 'latest.txt').read_text().strip() if (self.archive / 'latest.txt').exists() else ''
        return {'latest': latest, 'runs': rows(db, '''select r.run, r.meta, (select max(year) from people p where p.run=r.run) as last_year,
            (select count(*) from events e where e.run=r.run) as events from runs r order by r.run desc''')}

    def api_summary(self, db, q):
        run = q['run']
        years = rows(db, '''select year, count(*) as people, sum(realm=0) as mortal, sum(realm=1) as body, sum(realm=2) as qi,
            sum(realm>=3) as beyond, sum(spouse>=0)/2 as couples, sum(master>=0) as disciples, round(avg(reputation),1) as reputation
            from people where run=? and alive=1 group by year order by year''', (run,))
        kinds = rows(db, 'select kind, count(*) as n from events where run=? group by kind order by n desc', (run,))
        return {'years': years, 'kinds': kinds}

    def api_people(self, db, q):
        run = q['run']
        year = int(q.get('year') or self.latest_year(db, run))
        out = rows(db, '''select id, name, sex, born, alive, job, realm, layer, realm_label, root, reputation, mood, spouse, master,
            mother, father, factions from people where run=? and year=? order by realm desc, layer desc, reputation desc''', (run, year))
        best = {r['id']: r for r in rows(db, '''select id, skill, max(level) as level from skills where run=? and year=? group by id''', (run, year))}
        for p in out:
            p['age'] = ((year + 1) * 365 - p['born']) // 365
            b = best.get(p['id'])
            p['best_skill'], p['best_level'] = (b['skill'], b['level']) if b else ('', 0)
        return {'year': year, 'people': out}

    def api_person(self, db, q):
        run, pid = q['run'], int(q['id'])
        history = rows(db, '''select year, realm, layer, realm_label, qi, reputation, mood, job, spouse, master, alive
            from people where run=? and id=? order by year''', (run, pid))
        last = history[-1]['year'] if history else self.latest_year(db, run)
        person = (rows(db, 'select * from people where run=? and year=? and id=?', (run, last, pid)) or [{}])[0]
        names = {r['id']: r['name'] for r in rows(db, 'select id, name from people where run=? and year=?', (run, last))}
        skills = rows(db, 'select skill, level, xp from skills where run=? and year=? and id=? order by level desc', (run, last, pid))
        growth = rows(db, 'select year, skill, level from skills where run=? and id=? order by year', (run, pid))
        ties = rows(db, 'select b, opinion, trust, bonds from ties where run=? and year=? and a=? order by abs(opinion) desc', (run, last, pid))
        for t in ties:
            t['name'], t['bond_names'] = names.get(t['b'], f'#{t["b"]}'), bonds(t['bonds'])
        children = rows(db, 'select id, name from people where run=? and year=? and (mother=? or father=?)', (run, last, pid, pid))
        disciples = rows(db, 'select id, name from people where run=? and year=? and master=?', (run, last, pid))
        events = rows(db, 'select day, kind, text from events where run=? and (person=? or text like ?) order by day', (run, pid, f'%{person.get("name", "?")}%'))
        for key in ('mother', 'father', 'spouse', 'master'):
            if person.get(key, -1) is not None and person.get(key, -1) >= 0:
                person[key + '_name'] = names.get(person[key], f'#{person[key]}')
        return {'person': person, 'history': history, 'skills': skills, 'growth': growth, 'ties': ties,
                'children': children, 'disciples': disciples, 'events': events}

    def api_graph(self, db, q):
        run = q['run']
        year = int(q.get('year') or self.latest_year(db, run))
        layers = set((q.get('layers') or 'family,master,spouse,ties').split(','))
        min_opinion = float(q.get('min_opinion') or 40)
        people = rows(db, 'select id, name, sex, realm, layer, realm_label, alive, mother, father, spouse, master, reputation, job, factions from people where run=? and year=?', (run, year))
        edges = []
        for p in people:
            if 'family' in layers:
                for parent in (p['mother'], p['father']):
                    if parent is not None and parent >= 0:
                        edges.append({'a': parent, 'b': p['id'], 'kind': 'parent'})
            if 'spouse' in layers and p['spouse'] is not None and p['spouse'] > p['id']:
                edges.append({'a': p['id'], 'b': p['spouse'], 'kind': 'spouse'})
            if 'master' in layers and p['master'] is not None and p['master'] >= 0:
                edges.append({'a': p['master'], 'b': p['id'], 'kind': 'master'})
        if 'ties' in layers:
            for t in rows(db, 'select a, b, opinion, bonds from ties where run=? and year=? and abs(opinion)>=? and a<b', (run, year, min_opinion)):
                kind = 'enemy' if t['opinion'] < 0 or t['bonds'] & (128 | 256) else 'friend'
                edges.append({'a': t['a'], 'b': t['b'], 'kind': kind, 'opinion': t['opinion'], 'bonds': bonds(t['bonds'])})
        factions = rows(db, 'select fid, type, name, leader, size from factions where run=? and year=? and size>0', (run, year)) if 'factions' in layers else []
        return {'year': year, 'people': people, 'edges': edges, 'factions': factions}

    def api_events(self, db, q):
        run = q['run']
        sql, args = 'select day, person, kind, text from events where run=?', [run]
        if q.get('kind'):
            sql += ' and kind=?'
            args.append(q['kind'])
        if q.get('q'):
            sql += ' and text like ?'
            args.append(f'%{q["q"]}%')
        if q.get('from'):
            sql += ' and day>=?'
            args.append(int(q['from']) * 365)
        if q.get('to'):
            sql += ' and day<?'
            args.append((int(q['to']) + 1) * 365)
        sql += ' order by day limit ?'
        args.append(min(5000, int(q.get('limit') or 2000)))
        return {'events': rows(db, sql, args)}

    def api_factions(self, db, q):
        run = q['run']
        year = int(q.get('year') or self.latest_year(db, run))
        out = rows(db, 'select fid, type, name, leader, size, members, cohesion, reputation, absorbed_into from factions where run=? and year=? order by size desc', (run, year))
        names = {r['id']: r['name'] for r in rows(db, 'select id, name from people where run=? and year=?', (run, year))}
        for f in out:
            f['members'] = json.loads(f['members'])
            f['leader_name'] = names.get(f['leader'], '')
        return {'year': year, 'factions': out}


def make_handler(api: Api):
    class Handler(http.server.BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass

        def send(self, code, body: bytes, kind: str):
            self.send_response(code)
            self.send_header('Content-Type', kind)
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Cache-Control', 'no-store')
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            url = urllib.parse.urlparse(self.path)
            if url.path in ('/', '/index.html'):
                return self.send(200, VIEWER.read_bytes(), 'text/html; charset=utf-8')
            if url.path.startswith('/api/'):
                route = url.path[5:]
                if not hasattr(api, 'api_' + route) or not route.isidentifier():
                    return self.send(404, b'{"error":"unknown route"}', 'application/json')
                query = {k: v[0] for k, v in urllib.parse.parse_qs(url.query).items()}
                try:
                    body = json.dumps(api.call(route, query)).encode()
                except (KeyError, ValueError) as error:
                    return self.send(400, json.dumps({'error': str(error)}).encode(), 'application/json')
                return self.send(200, body, 'application/json')
            self.send(404, b'not found', 'text/plain')
    return Handler


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive', type=Path, help='folder holding latest.txt and run_* folders')
    parser.add_argument('--port', type=int, default=8765)
    parser.add_argument('--index-only', action='store_true')
    options = parser.parse_args()
    archive = find_archive_root(options.archive or DEFAULT_ARCHIVE)
    api = Api(archive / 'archive.sqlite', archive)
    api.refresh()
    print(f'Indexed {archive}')
    if options.index_only:
        return
    # Loopback only: the archive is private and the server has no authentication.
    server = http.server.ThreadingHTTPServer(('127.0.0.1', options.port), make_handler(api))
    print(f'Archive viewer: http://127.0.0.1:{options.port}/')
    server.serve_forever()


if __name__ == '__main__':
    main()
