-- psql "$DATABASE_URL" -f e2e/seed.sql

INSERT INTO universities (name, domain)
VALUES ('Universidad de Test', 'test.edu')
ON CONFLICT (domain) DO UPDATE SET name = EXCLUDED.name
RETURNING id;

DO $$
DECLARE
    v_uni_id INTEGER;
    v_study_id INTEGER;
    v_user_id INTEGER;
    v_subj_id INTEGER;
BEGIN
    SELECT id INTO v_uni_id FROM universities WHERE domain = 'test.edu';

    INSERT INTO studies (name, university_id)
    VALUES ('Grado en Testing :D', v_uni_id)
    ON CONFLICT DO NOTHING;

    SELECT id INTO v_study_id FROM studies WHERE name = 'Grado en Testing :D' AND university_id = v_uni_id;

    INSERT INTO users (google_sub, email, username, hd, study_id, university_id, role)
    VALUES ('e2e-test-sub', 'e2e@test.edu', 'e2e-tester', 'test.edu', v_study_id, v_uni_id, 'user')
    ON CONFLICT (google_sub) DO UPDATE
        SET study_id = EXCLUDED.study_id,
            university_id = EXCLUDED.university_id,
            username = EXCLUDED.username;

    SELECT id INTO v_user_id FROM users WHERE google_sub = 'e2e-test-sub';

    INSERT INTO subjects (study_id, name, year) VALUES (v_study_id, 'Asignatura E2E', '1') ON CONFLICT DO NOTHING;
    SELECT id INTO v_subj_id FROM subjects WHERE name = 'Asignatura E2E' AND study_id = v_study_id LIMIT 1;

    INSERT INTO resources (owner_id, subject_id, title, description)
    VALUES (v_user_id, v_subj_id, 'Recurso de prueba', 'Creado por el seed E2E')
    ON CONFLICT DO NOTHING;
END $$;
