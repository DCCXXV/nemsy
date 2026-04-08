#!/usr/bin/env python3
"""scrapes all ucm degrees and their subjects and inserts them to the db"""

import re
import sys
import time

import psycopg2
import requests
from bs4 import BeautifulSoup

BASE_URL = "https://www.ucm.es"
SESSION = requests.Session()
SESSION.headers["User-Agent"] = "Mozilla/5.0"


def get_all_degrees():
    resp = SESSION.get(f"{BASE_URL}/estudios/grado", timeout=10)
    soup = BeautifulSoup(resp.content, "html.parser")

    degrees = {}
    for link in soup.find_all("a", href=True):
        href = link["href"]
        if "/estudios/grado-" not in href:
            continue
        url = href if href.startswith("http") else BASE_URL + href
        name = link.get_text().strip()
        if url not in degrees and name:
            degrees[url] = name

    return [(name, url) for url, name in degrees.items()]


def find_plan_url(degree_url):
    resp = SESSION.get(degree_url, timeout=15)
    soup = BeautifulSoup(resp.content, "html.parser")

    for link in soup.find_all("a", href=True):
        text = link.get_text().lower()
        href = link["href"]
        if (
            "planificación docente" in text
            or "planificacion docente" in text
            or "-plan" in href
        ):
            return href if href.startswith("http") else BASE_URL + href

    return None


def parse_year_from_heading(text):
    text = text.lower()
    patterns = [
        (r"primer\w*\s+curso", 1),
        (r"1[erº°]\s*curso", 1),
        (r"curso\s*1", 1),
        (r"segund\w*\s+curso", 2),
        (r"2[º°]\s*curso", 2),
        (r"curso\s*2", 2),
        (r"tercer\w*\s+curso", 3),
        (r"3[erº°]\s*curso", 3),
        (r"curso\s*3", 3),
        (r"cuart\w*\s+curso", 4),
        (r"4[º°]\s*curso", 4),
        (r"curso\s*4", 4),
        (r"quint\w*\s+curso", 5),
        (r"5[º°]\s*curso", 5),
        (r"curso\s*5", 5),
    ]
    for pattern, year in patterns:
        if re.search(pattern, text):
            return year
    return None


def extract_subject_name(cells):
    for cell in cells:
        link = cell.find("a")
        if link:
            name = link.get_text().strip()
            if name and not name.isdigit() and len(name) > 3:
                return name

    skip = {"obligatoria", "optativa", "básica", "ob", "op", "formación básica"}
    best = ""
    for cell in cells:
        text = cell.get_text().strip()
        if text.lower() in skip or re.match(r"^\d+(\.\d+)?\s*(ECTS)?$", text, re.I):
            continue
        if len(text) > len(best) and not text.isdigit():
            best = text
    return best if len(best) > 3 else None


def get_subjects(degree_url):
    plan_url = find_plan_url(degree_url)
    if not plan_url:
        print(f"  no plan URL found")
        return []
    print(f"  plan: {plan_url}")

    resp = SESSION.get(plan_url, timeout=15)
    soup = BeautifulSoup(resp.content, "html.parser")

    subjects = []
    current_year = None

    for el in soup.find_all(["h1", "h2", "h3", "h4", "h5", "table"]):
        if el.name != "table":
            year = parse_year_from_heading(el.get_text())
            if year is not None:
                current_year = year
            continue

        for row in el.find_all("tr")[1:]:
            cells = row.find_all(["td", "th"])
            if len(cells) < 2:
                continue

            name = extract_subject_name(cells)
            if not name:
                continue

            year_str = str(current_year) if current_year and current_year > 0 else "4"
            subjects.append((name, year_str))

    return subjects


def seed(database_url):
    conn = psycopg2.connect(database_url)
    cur = conn.cursor()

    cur.execute("SELECT id FROM universities WHERE domain = 'ucm.es'")
    row = cur.fetchone()
    if not row:
        print("ERROR: UCM not found in table RUN seed-universities FIRST!!")
        sys.exit(1)
    university_id = row[0]
    print(f"UCM university_id = {university_id}")

    degrees = get_all_degrees()
    print(f"Found {len(degrees)} degrees")

    for i, (name, url) in enumerate(degrees, 1):
        print(f"[{i}/{len(degrees)}] {name}")

        cur.execute(
            "INSERT INTO studies (name, university_id) VALUES (%s, %s) ON CONFLICT DO NOTHING RETURNING id",
            (name, university_id),
        )
        row = cur.fetchone()
        if not row:
            print("  skipped (duplicate)")
            continue
        study_id = row[0]

        try:
            subjects = get_subjects(url)
        except Exception as e:
            print(f"  error getting subjects: {e}")
            subjects = []

        for subj_name, year in subjects:
            cur.execute(
                "INSERT INTO subjects (study_id, name, year) VALUES (%s, %s, %s)",
                (study_id, subj_name, year),
            )

        print(f"  {len(subjects)} subjects")
        conn.commit()
        time.sleep(0.5)

    cur.close()
    conn.close()
    print("Done")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <DATABASE_URL>")
        sys.exit(1)
    seed(sys.argv[1])
