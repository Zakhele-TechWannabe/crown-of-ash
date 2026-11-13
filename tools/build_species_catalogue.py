#!/usr/bin/env python3
"""Build data/wild/species.json: every species recorded in a real temperate Chinese mountain range.

Source: GBIF occurrence records in the Qinling box (33.3-34.3 N, 106.5-109.5 E), faceted by species,
then each species' taxonomy and English name from the GBIF Backbone Taxonomy (CC BY 4.0).
Traits are not invented per species: they come from data/wild/trait_rules.json (by family, order,
class, phylum or kingdom, most specific first) and are overridden by the field numbers in
data/wild/curated.json, which also adds the village animals and the large predators the records miss.

Usage: python3 tools/build_species_catalogue.py [--refresh]   (--refresh re-downloads from GBIF)
"""
import json
import sys
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WILD = ROOT / "data" / "wild"
SOURCE = WILD / "source" / "gbif_qinling.json"
BOX = {"decimalLatitude": "33.3,34.3", "decimalLongitude": "106.5,109.5"}
# Living things seen or collected in the wild: no fossils (extinct species) and no zoo or garden specimens.
BASIS = ["HUMAN_OBSERVATION", "PRESERVED_SPECIMEN", "MACHINE_OBSERVATION", "OBSERVATION", "MATERIAL_SAMPLE", "OCCURRENCE"]
SKIP_KINGDOMS = {"Bacteria", "Archaea", "Viruses", "Protozoa", "Chromista", "incertae sedis"}
API = "https://api.gbif.org/v1"
FIELDS = ["canonicalName", "vernacularName", "kingdom", "phylum", "class", "order", "family", "genus", "rank"]


def get(url: str) -> dict:
    for attempt in range(5):
        try:
            with urllib.request.urlopen(url, timeout=30) as response:
                return json.load(response)
        except Exception:
            time.sleep(1 + attempt * 2)
    raise RuntimeError("GBIF did not answer: " + url)


def download() -> dict:
    query = "&".join(f"{k}={v}" for k, v in BOX.items()) + "".join(f"&basisOfRecord={b}" for b in BASIS)
    cached = {}
    if SOURCE.exists():
        cached = {int(r["key"]): r for r in json.loads(SOURCE.read_text())["species"]}
    facets = get(f"{API}/occurrence/search?{query}&limit=0&facet=speciesKey&facetLimit=20000")
    counts = {int(c["name"]): int(c["count"]) for c in facets["facets"][0]["counts"]}
    print(f"{len(counts)} species in the box; fetching names", file=sys.stderr)

    def one(key: int) -> dict:
        if key in cached:
            return {**cached[key], "records": counts[key]}
        record = get(f"{API}/species/{key}")
        return {"key": key, "records": counts[key], **{f: record.get(f, "") for f in FIELDS}}

    with ThreadPoolExecutor(max_workers=8) as pool:
        species = list(pool.map(one, sorted(counts)))
    data = {"retrieved": date.today().isoformat(), "box": BOX, "basis_of_record": BASIS, "species": species,
            "citation": "GBIF.org occurrence search (Qinling box) and GBIF Backbone Taxonomy, CC BY 4.0, https://www.gbif.org"}
    SOURCE.parent.mkdir(parents=True, exist_ok=True)
    SOURCE.write_text(json.dumps(data, ensure_ascii=False, indent=0))
    return data


def traits_for(record: dict, rules: dict) -> dict:
    """Merge rule layers from the broadest taxon to the most specific."""
    merged = dict(rules["default"])
    for level in ["kingdom", "phylum", "class", "order", "family"]:
        merged.update(rules[level].get(record.get(level) or "", {}))
    return merged


def tier_for(entry: dict) -> str:
    if entry.get("tier"):
        return entry["tier"]
    vertebrate = entry["class"] in ["Mammalia", "Aves", "Amphibia", "Squamata", "Testudines", "Actinopterygii", "Crocodylia"]
    if entry["class"] == "Mammalia" and entry["mass"] >= 5:
        return "individual"
    return "population" if vertebrate else "guild"


def build() -> None:
    data = json.loads(SOURCE.read_text()) if SOURCE.exists() and "--refresh" not in sys.argv else download()
    rules = json.loads((WILD / "trait_rules.json").read_text())
    curated = json.loads((WILD / "curated.json").read_text())
    by_name = {c["sci"]: c for c in curated["species"]}
    out = []
    seen = set()
    for record in data["species"]:
        name = record.get("canonicalName") or ""
        if record.get("rank") != "SPECIES" or not name or name in seen or record.get("kingdom") in SKIP_KINGDOMS:
            continue
        seen.add(name)
        entry = {"id": record["key"], "sci": name, "name": record.get("vernacularName") or name,
                 "kingdom": record.get("kingdom", ""), "class": record.get("class", ""), "order": record.get("order", ""),
                 "family": record.get("family", ""), "records": record["records"], "source": "gbif"}
        entry.update(traits_for(record, rules))
        if name in by_name:
            entry.update(by_name[name])
            entry["source"] = "gbif+curated"
        entry["tier"] = tier_for(entry)
        out.append(entry)
    for extra in curated["species"]:
        if extra["sci"] not in seen:
            entry = {"id": -len(out) - 1, "records": 0, "source": "curated", **traits_for(extra, rules), **extra}
            entry["tier"] = tier_for(entry)
            out.append(entry)
    out.sort(key=lambda e: (["individual", "population", "guild"].index(e["tier"]), e["kingdom"], e["class"], e["order"], e["family"], e["sci"]))
    catalogue = {"retrieved": data["retrieved"], "citation": data["citation"], "species": out}
    (WILD / "species.json").write_text(json.dumps(catalogue, ensure_ascii=False, separators=(",", ":")))
    tiers = {t: sum(1 for e in out if e["tier"] == t) for t in ["individual", "population", "guild"]}
    print(f"{len(out)} species written: {tiers}")


if __name__ == "__main__":
    build()
