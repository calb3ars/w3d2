CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(16) NOT NULL,
  lname VARCHAR(16) NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  author_id INTEGER NOT NULL,
  title VARCHAR(50) NOT NULL,
  body TEXT,

  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_followers (
  id INTEGER PRIMARY KEY,
  follower_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (follower_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  parent_id INTEGER,
  body TEXT NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Gilbert', 'Green'),
  ('Andrew', 'Jiang'),
  ('Paul', 'Schmitt'),
  ('Bill', 'Gates'),
  ('Tony', 'Jaa'),
  ('Jackie', 'Chan'),
  ('Jaden', 'Smith');

INSERT INTO
  questions (author_id, title, body)
VALUES
  ((SELECT id FROM users WHERE fname = 'Jaden' AND lname = 'Smith'), 'How do I hit things harder?', NULL),
  ((SELECT id FROM users WHERE fname = 'Gilbert' AND lname = 'Green'), 'What is a byte?', 'And why should I care?'),
  ((SELECT id FROM users WHERE fname = 'Andrew' AND lname = 'Jiang'), 'Should I hit my computer?', 'And if so, how hard? It''s being mean to me!');

INSERT INTO
  question_followers (question_id, follower_id)
VALUES
  ((SELECT id FROM questions WHERE title LIKE 'How do I%'), (SELECT id FROM users WHERE fname = 'Jackie')),
  ((SELECT id FROM questions WHERE title LIKE 'How do I%'), (SELECT id FROM users WHERE fname = 'Tony')),
  ((SELECT id FROM questions WHERE title LIKE 'What is%'), (SELECT id FROM users WHERE fname = 'Bill')),
  ((SELECT id FROM questions WHERE title LIKE 'What is%'), (SELECT id FROM users WHERE fname = 'Andrew'));

INSERT INTO
  likes (user_id, question_id)
VALUES
  (5, 1),
  (6, 1),
  (2, 2),
  (4, 2),
  (7, 1);

INSERT INTO
  replies (question_id, user_id, parent_id, body)
VALUES
  (1, 6, NULL, 'With your fists'),
  (1, 5, 1, 'And plenty of juice'),
  (4, 2, NULL, 'Something you take from an Apple');
