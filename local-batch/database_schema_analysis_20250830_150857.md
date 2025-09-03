✅ Connected to PostgreSQL database: prod
# PostgreSQL Database Schema Analysis Report
**Database:** prod
**Generated:** 2025-08-30 15:07:37

## Database Overview
**Total Schemas:** 3
**Schemas:** lesson_planner_fe, practise_improve_pilot, public

## Schema: `lesson_planner_fe`

### Tables Overview
| Table Name           | Type       | Size   |   Rows | Description    |
|:---------------------|:-----------|:-------|-------:|:---------------|
| class                | BASE TABLE | 80 kB  |     45 | No description |
| feedback             | BASE TABLE | 128 kB |     18 | No description |
| lesson               | BASE TABLE | 136 kB |    130 | No description |
| lesson_plan          | BASE TABLE | 584 kB |    130 | No description |
| lesson_plan_instance | BASE TABLE | 128 kB |     75 | No description |
| reflection           | BASE TABLE | 96 kB  |      4 | No description |
| school               | BASE TABLE | 64 kB  |     36 | No description |
| subject              | BASE TABLE | 48 kB  |      1 | No description |
| teacher              | BASE TABLE | 96 kB  |     52 | No description |
| topic                | BASE TABLE | 96 kB  |      8 | No description |

**Total Tables:** 10
**Total Rows:** 499

### Table: `class`
| Metric      | Value   |
|:------------|:--------|
| Size        | 80 kB   |
| Live Tuples | 45      |
| Dead Tuples | 0       |
| Inserts     | 45      |
| Updates     | 0       |
| Deletes     | 0       |

#### Columns
| Column     | Type                        | Constraints   | Default            | Description   |
|:-----------|:----------------------------|:--------------|:-------------------|:--------------|
| class_id   | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| school_id  | uuid                        | NOT NULL      | -                  | -             |
| teacher_id | uuid                        | NOT NULL      | -                  | -             |
| name       | text                        | NOT NULL      | -                  | -             |
| created_at | timestamp without time zone | -             | CURRENT_TIMESTAMP  | -             |
| updated_at | timestamp without time zone | -             | CURRENT_TIMESTAMP  | -             |
| deleted_at | timestamp without time zone | -             | -                  | -             |

#### Data Quality Analysis
✅ No data quality issues detected

### Table: `feedback`
| Metric      | Value   |
|:------------|:--------|
| Size        | 128 kB  |
| Live Tuples | 18      |
| Dead Tuples | 6       |
| Inserts     | 19      |
| Updates     | 14      |
| Deletes     | 1       |

#### Columns
| Column                  | Type                        | Constraints   | Default            | Description   |
|:------------------------|:----------------------------|:--------------|:-------------------|:--------------|
| id                      | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| id                      | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| id                      | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| id                      | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| teacher_id              | uuid                        | NOT NULL      | -                  | -             |
| teacher_id              | uuid                        | NOT NULL      | -                  | -             |
| rating                  | integer(32)                 | NOT NULL      | -                  | -             |
| rating                  | integer(32)                 | NOT NULL      | -                  | -             |
| comment                 | text                        | -             | -                  | -             |
| comment                 | text                        | -             | -                  | -             |
| user_email              | text                        | -             | -                  | -             |
| user_email              | text                        | -             | -                  | -             |
| lesson_plan_instance_id | uuid                        | NOT NULL      | -                  | -             |
| lesson_plan_instance_id | uuid                        | NOT NULL      | -                  | -             |
| created_at              | timestamp without time zone | -             | CURRENT_TIMESTAMP  | -             |
| created_at              | timestamp without time zone | -             | CURRENT_TIMESTAMP  | -             |
| updated_at              | timestamp without time zone | -             | CURRENT_TIMESTAMP  | -             |
| updated_at              | timestamp without time zone | -             | CURRENT_TIMESTAMP  | -             |
| deleted_at              | timestamp without time zone | -             | -                  | -             |
| deleted_at              | timestamp without time zone | -             | -                  | -             |

#### Data Quality Analysis
⚠️ Column 'comment' has 7 empty strings
⚠️ Column 'comment' has 7 empty strings

### Table: `lesson`
| Metric      | Value   |
|:------------|:--------|
| Size        | 136 kB  |
| Live Tuples | 130     |
| Dead Tuples | 0       |
| Inserts     | 130     |
| Updates     | 0       |
| Deletes     | 0       |

#### Columns
| Column              | Type                        | Constraints   | Default            | Description   |
|:--------------------|:----------------------------|:--------------|:-------------------|:--------------|
| lesson_id           | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| topic_id            | uuid                        | NOT NULL      | -                  | -             |
| subject_code        | text                        | NOT NULL      | -                  | -             |
| title               | text                        | NOT NULL      | -                  | -             |
| description         | text                        | -             | -                  | -             |
| lesson_number       | integer(32)                 | NOT NULL      | -                  | -             |
| duration_minutes    | integer(32)                 | -             | -                  | -             |
| learning_objectives | jsonb                       | -             | -                  | -             |
| resources           | jsonb                       | -             | -                  | -             |
| created_at          | timestamp without time zone | -             | CURRENT_TIMESTAMP  | -             |
| updated_at          | timestamp without time zone | -             | CURRENT_TIMESTAMP  | -             |
| deleted_at          | timestamp without time zone | -             | -                  | -             |

#### Data Quality Analysis
✅ No data quality issues detected

### Table: `lesson_plan`
| Metric      | Value   |
|:------------|:--------|
| Size        | 584 kB  |
| Live Tuples | 130     |
| Dead Tuples | 0       |
| Inserts     | 130     |
| Updates     | 0       |
| Deletes     | 0       |

#### Columns
| Column             | Type                        | Constraints   | Default            | Description   |
|:-------------------|:----------------------------|:--------------|:-------------------|:--------------|
| id                 | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| lesson_id          | uuid                        | NOT NULL      | -                  | -             |
| subject_code       | text                        | NOT NULL      | -                  | -             |
| teacher_id         | uuid                        | -             | -                  | -             |
| title              | text                        | NOT NULL      | -                  | -             |
| content            | jsonb                       | NOT NULL      | -                  | -             |
| user_email         | text                        | -             | -                  | -             |
| owner_email        | text                        | -             | -                  | -             |
| owner_school_id    | text                        | -             | -                  | -             |
| parent_id          | uuid                        | -             | -                  | -             |
| docx_s3_key        | text                        | -             | -                  | -             |
| pdf_s3_key         | text                        | -             | -                  | -             |
| html_s3_key        | text                        | -             | -                  | -             |
| shared_with_school | boolean                     | NOT NULL      | false              | -             |
| created_at         | timestamp without time zone | -             | CURRENT_TIMESTAMP  | -             |
| updated_at         | timestamp without time zone | -             | CURRENT_TIMESTAMP  | -             |
| deleted_at         | timestamp without time zone | -             | -                  | -             |

#### Data Quality Analysis
✅ No data quality issues detected

### Table: `lesson_plan_instance`
| Metric      | Value   |
|:------------|:--------|
| Size        | 128 kB  |
| Live Tuples | 75      |
| Dead Tuples | 9       |
| Inserts     | 77      |
| Updates     | 27      |
| Deletes     | 2       |

#### Columns
| Column              | Type                        | Constraints   | Default                    | Description   |
|:--------------------|:----------------------------|:--------------|:---------------------------|:--------------|
| instance_id         | uuid                        | PK | NOT NULL | uuid_generate_v4()         | -             |
| class_id            | uuid                        | NOT NULL      | -                          | -             |
| class_present_count | integer(32)                 | -             | 0                          | -             |
| class_absent_count  | integer(32)                 | -             | 0                          | -             |
| teacher_id          | uuid                        | NOT NULL      | -                          | -             |
| lesson_plan_id      | uuid                        | NOT NULL      | -                          | -             |
| lesson_date         | date                        | NOT NULL      | -                          | -             |
| content             | jsonb                       | -             | -                          | -             |
| status              | character varying(20)       | -             | 'draft'::character varying | -             |
| created_at          | timestamp without time zone | -             | CURRENT_TIMESTAMP          | -             |
| updated_at          | timestamp without time zone | -             | CURRENT_TIMESTAMP          | -             |
| deleted_at          | timestamp without time zone | -             | -                          | -             |
| docx_s3_key         | text                        | -             | -                          | -             |
| pdf_s3_key          | text                        | -             | -                          | -             |
| html_s3_key         | text                        | -             | -                          | -             |

#### Data Quality Analysis
✅ No data quality issues detected

### Table: `reflection`
| Metric      | Value   |
|:------------|:--------|
| Size        | 96 kB   |
| Live Tuples | 4       |
| Dead Tuples | 0       |
| Inserts     | 4       |
| Updates     | 0       |
| Deletes     | 0       |

#### Columns
| Column                        | Type                        | Constraints   | Default            | Description   |
|:------------------------------|:----------------------------|:--------------|:-------------------|:--------------|
| id                            | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| teacher_id                    | uuid                        | NOT NULL      | -                  | -             |
| user_email                    | text                        | -             | -                  | -             |
| lesson_plan_instance_id       | uuid                        | NOT NULL      | -                  | -             |
| objectives_realistic          | text                        | -             | -                  | -             |
| learner_outcomes              | text                        | -             | -                  | -             |
| learning_atmosphere           | text                        | -             | -                  | -             |
| plan_changes                  | text                        | -             | -                  | -             |
| success_factors               | text                        | -             | -                  | -             |
| improvement_suggestions       | text                        | -             | -                  | -             |
| next_lesson_insights          | text                        | -             | -                  | -             |
| created_at                    | timestamp without time zone | -             | CURRENT_TIMESTAMP  | -             |
| updated_at                    | timestamp without time zone | -             | CURRENT_TIMESTAMP  | -             |
| deleted_at                    | timestamp without time zone | -             | -                  | -             |
| differentiation_effectiveness | text                        | -             | -                  | -             |
| adherence_to_timings          | text                        | -             | -                  | -             |

#### Data Quality Analysis
⚠️ Column 'learner_outcomes' has 1 empty strings
⚠️ Column 'learning_atmosphere' has 1 empty strings
⚠️ Column 'plan_changes' has 4 empty strings
⚠️ Column 'success_factors' has 4 empty strings
⚠️ Column 'improvement_suggestions' has 4 empty strings
⚠️ Column 'next_lesson_insights' has 4 empty strings
⚠️ Column 'differentiation_effectiveness' has 1 empty strings
⚠️ Column 'adherence_to_timings' has 4 empty strings

### Table: `school`
| Metric      | Value   |
|:------------|:--------|
| Size        | 64 kB   |
| Live Tuples | 36      |
| Dead Tuples | 0       |
| Inserts     | 36      |
| Updates     | 0       |
| Deletes     | 0       |

#### Columns
| Column     | Type                        | Constraints   | Default            | Description   |
|:-----------|:----------------------------|:--------------|:-------------------|:--------------|
| school_id  | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| name       | text                        | NOT NULL      | -                  | -             |
| created_at | timestamp without time zone | -             | CURRENT_TIMESTAMP  | -             |
| updated_at | timestamp without time zone | -             | CURRENT_TIMESTAMP  | -             |
| deleted_at | timestamp without time zone | -             | -                  | -             |

#### Data Quality Analysis
✅ No data quality issues detected

### Table: `subject`
| Metric      | Value   |
|:------------|:--------|
| Size        | 48 kB   |
| Live Tuples | 1       |
| Dead Tuples | 1       |
| Inserts     | 1       |
| Updates     | 1       |
| Deletes     | 0       |

#### Columns
| Column       | Type                        | Constraints   | Default           | Description   |
|:-------------|:----------------------------|:--------------|:------------------|:--------------|
| subject_code | text                        | PK | NOT NULL | -                 | -             |
| name         | text                        | NOT NULL      | -                 | -             |
| image_url    | text                        | -             | -                 | -             |
| created_at   | timestamp without time zone | -             | CURRENT_TIMESTAMP | -             |
| updated_at   | timestamp without time zone | -             | CURRENT_TIMESTAMP | -             |
| deleted_at   | timestamp without time zone | -             | -                 | -             |

#### Data Quality Analysis
✅ No data quality issues detected

### Table: `teacher`
| Metric      | Value   |
|:------------|:--------|
| Size        | 96 kB   |
| Live Tuples | 52      |
| Dead Tuples | 1       |
| Inserts     | 53      |
| Updates     | 0       |
| Deletes     | 1       |

#### Columns
| Column     | Type                        | Constraints   | Default            | Description   |
|:-----------|:----------------------------|:--------------|:-------------------|:--------------|
| teacher_id | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| school_id  | uuid                        | NOT NULL      | -                  | -             |
| email      | text                        | NOT NULL      | -                  | -             |
| first_name | text                        | NOT NULL      | -                  | -             |
| last_name  | text                        | NOT NULL      | -                  | -             |
| created_at | timestamp without time zone | -             | CURRENT_TIMESTAMP  | -             |
| updated_at | timestamp without time zone | -             | CURRENT_TIMESTAMP  | -             |
| deleted_at | timestamp without time zone | -             | -                  | -             |

#### Data Quality Analysis
✅ No data quality issues detected

### Table: `topic`
| Metric      | Value   |
|:------------|:--------|
| Size        | 96 kB   |
| Live Tuples | 8       |
| Dead Tuples | 8       |
| Inserts     | 8       |
| Updates     | 8       |
| Deletes     | 0       |

#### Columns
| Column       | Type                        | Constraints   | Default            | Description   |
|:-------------|:----------------------------|:--------------|:-------------------|:--------------|
| topic_id     | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| subject_code | text                        | NOT NULL      | -                  | -             |
| name         | text                        | NOT NULL      | -                  | -             |
| topic_number | integer(32)                 | NOT NULL      | -                  | -             |
| created_at   | timestamp without time zone | -             | CURRENT_TIMESTAMP  | -             |
| updated_at   | timestamp without time zone | -             | CURRENT_TIMESTAMP  | -             |
| deleted_at   | timestamp without time zone | -             | -                  | -             |
| image_url    | text                        | -             | -                  | -             |

#### Data Quality Analysis
✅ No data quality issues detected

### Indexes
| Table                | Index Name                              | Definition                                                                                                                                  | Size   |
|:---------------------|:----------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------|:-------|
| class                | class_pkey                              | CREATE UNIQUE INDEX class_pkey ON lesson_planner_fe.class USING btree (class_id)                                                            | 16 kB  |
| class                | idx_class_name                          | CREATE INDEX idx_class_name ON lesson_planner_fe.class USING btree (name)                                                                   | 16 kB  |
| class                | idx_class_school                        | CREATE INDEX idx_class_school ON lesson_planner_fe.class USING btree (school_id)                                                            | 16 kB  |
| class                | idx_class_teacher                       | CREATE INDEX idx_class_teacher ON lesson_planner_fe.class USING btree (teacher_id)                                                          | 16 kB  |
| feedback             | feedback_pkey                           | CREATE UNIQUE INDEX feedback_pkey ON lesson_planner_fe.feedback USING btree (id)                                                            | 16 kB  |
| feedback             | idx_feedback_lesson_plan                | CREATE INDEX idx_feedback_lesson_plan ON lesson_planner_fe.feedback USING btree (lesson_plan_instance_id)                                   | 16 kB  |
| feedback             | idx_feedback_lesson_plan_instance       | CREATE INDEX idx_feedback_lesson_plan_instance ON lesson_planner_fe.feedback USING btree (lesson_plan_instance_id)                          | 16 kB  |
| feedback             | idx_feedback_rating                     | CREATE INDEX idx_feedback_rating ON lesson_planner_fe.feedback USING btree (rating)                                                         | 16 kB  |
| feedback             | idx_feedback_teacher                    | CREATE INDEX idx_feedback_teacher ON lesson_planner_fe.feedback USING btree (teacher_id)                                                    | 16 kB  |
| feedback             | idx_feedback_user                       | CREATE INDEX idx_feedback_user ON lesson_planner_fe.feedback USING btree (user_email)                                                       | 16 kB  |
| feedback             | unique_teacher_lesson_instance_feedback | CREATE UNIQUE INDEX unique_teacher_lesson_instance_feedback ON lesson_planner_fe.feedback USING btree (teacher_id, lesson_plan_instance_id) | 16 kB  |
| lesson               | idx_lesson_number_1                     | CREATE INDEX idx_lesson_number_1 ON lesson_planner_fe.lesson USING btree (lesson_number)                                                    | 16 kB  |
| lesson               | idx_lesson_subject_1                    | CREATE INDEX idx_lesson_subject_1 ON lesson_planner_fe.lesson USING btree (subject_code)                                                    | 16 kB  |
| lesson               | idx_lesson_topic_1                      | CREATE INDEX idx_lesson_topic_1 ON lesson_planner_fe.lesson USING btree (topic_id)                                                          | 16 kB  |
| lesson               | lesson_pkey_1                           | CREATE UNIQUE INDEX lesson_pkey_1 ON lesson_planner_fe.lesson USING btree (lesson_id)                                                       | 16 kB  |
| lesson               | lesson_topic_number_unique_1            | CREATE UNIQUE INDEX lesson_topic_number_unique_1 ON lesson_planner_fe.lesson USING btree (topic_id, lesson_number)                          | 16 kB  |
| lesson_plan          | idx_lesson_plan_lesson                  | CREATE INDEX idx_lesson_plan_lesson ON lesson_planner_fe.lesson_plan USING btree (lesson_id)                                                | 16 kB  |
| lesson_plan          | idx_lesson_plan_owner                   | CREATE INDEX idx_lesson_plan_owner ON lesson_planner_fe.lesson_plan USING btree (owner_email)                                               | 16 kB  |
| lesson_plan          | idx_lesson_plan_subject                 | CREATE INDEX idx_lesson_plan_subject ON lesson_planner_fe.lesson_plan USING btree (subject_code)                                            | 16 kB  |
| lesson_plan          | idx_lesson_plan_teacher                 | CREATE INDEX idx_lesson_plan_teacher ON lesson_planner_fe.lesson_plan USING btree (teacher_id)                                              | 16 kB  |
| lesson_plan          | idx_lesson_plan_user                    | CREATE INDEX idx_lesson_plan_user ON lesson_planner_fe.lesson_plan USING btree (user_email)                                                 | 16 kB  |
| lesson_plan          | lesson_plan_pkey                        | CREATE UNIQUE INDEX lesson_plan_pkey ON lesson_planner_fe.lesson_plan USING btree (id)                                                      | 16 kB  |
| lesson_plan_instance | idx_instance_class                      | CREATE INDEX idx_instance_class ON lesson_planner_fe.lesson_plan_instance USING btree (class_id)                                            | 16 kB  |
| lesson_plan_instance | idx_instance_date                       | CREATE INDEX idx_instance_date ON lesson_planner_fe.lesson_plan_instance USING btree (lesson_date)                                          | 16 kB  |
| lesson_plan_instance | idx_instance_lesson_plan                | CREATE INDEX idx_instance_lesson_plan ON lesson_planner_fe.lesson_plan_instance USING btree (lesson_plan_id)                                | 16 kB  |
| lesson_plan_instance | idx_instance_teacher                    | CREATE INDEX idx_instance_teacher ON lesson_planner_fe.lesson_plan_instance USING btree (teacher_id)                                        | 16 kB  |
| lesson_plan_instance | lesson_plan_instance_pkey               | CREATE UNIQUE INDEX lesson_plan_instance_pkey ON lesson_planner_fe.lesson_plan_instance USING btree (instance_id)                           | 16 kB  |
| reflection           | idx_reflection_lesson_plan_instance     | CREATE INDEX idx_reflection_lesson_plan_instance ON lesson_planner_fe.reflection USING btree (lesson_plan_instance_id)                      | 16 kB  |
| reflection           | idx_reflection_teacher                  | CREATE INDEX idx_reflection_teacher ON lesson_planner_fe.reflection USING btree (teacher_id)                                                | 16 kB  |
| reflection           | idx_reflection_user                     | CREATE INDEX idx_reflection_user ON lesson_planner_fe.reflection USING btree (user_email)                                                   | 16 kB  |
| reflection           | reflection_pkey                         | CREATE UNIQUE INDEX reflection_pkey ON lesson_planner_fe.reflection USING btree (id)                                                        | 16 kB  |
| reflection           | uq_reflection_teacher_lesson            | CREATE UNIQUE INDEX uq_reflection_teacher_lesson ON lesson_planner_fe.reflection USING btree (teacher_id, lesson_plan_instance_id)          | 16 kB  |
| school               | idx_school_name                         | CREATE INDEX idx_school_name ON lesson_planner_fe.school USING btree (name)                                                                 | 16 kB  |
| school               | school_name_unique                      | CREATE UNIQUE INDEX school_name_unique ON lesson_planner_fe.school USING btree (name)                                                       | 16 kB  |
| school               | school_pkey                             | CREATE UNIQUE INDEX school_pkey ON lesson_planner_fe.school USING btree (school_id)                                                         | 16 kB  |
| subject              | idx_subject_name                        | CREATE INDEX idx_subject_name ON lesson_planner_fe.subject USING btree (name)                                                               | 16 kB  |
| subject              | subject_pkey                            | CREATE UNIQUE INDEX subject_pkey ON lesson_planner_fe.subject USING btree (subject_code)                                                    | 16 kB  |
| teacher              | idx_teacher_email                       | CREATE INDEX idx_teacher_email ON lesson_planner_fe.teacher USING btree (email)                                                             | 16 kB  |
| teacher              | idx_teacher_name                        | CREATE INDEX idx_teacher_name ON lesson_planner_fe.teacher USING btree (last_name, first_name)                                              | 16 kB  |
| teacher              | idx_teacher_school                      | CREATE INDEX idx_teacher_school ON lesson_planner_fe.teacher USING btree (school_id)                                                        | 16 kB  |
| teacher              | teacher_email_unique                    | CREATE UNIQUE INDEX teacher_email_unique ON lesson_planner_fe.teacher USING btree (email)                                                   | 16 kB  |
| teacher              | teacher_pkey                            | CREATE UNIQUE INDEX teacher_pkey ON lesson_planner_fe.teacher USING btree (teacher_id)                                                      | 16 kB  |
| topic                | idx_topic_name                          | CREATE INDEX idx_topic_name ON lesson_planner_fe.topic USING btree (name)                                                                   | 16 kB  |
| topic                | idx_topic_number                        | CREATE INDEX idx_topic_number ON lesson_planner_fe.topic USING btree (topic_number)                                                         | 16 kB  |
| topic                | idx_topic_subject                       | CREATE INDEX idx_topic_subject ON lesson_planner_fe.topic USING btree (subject_code)                                                        | 16 kB  |
| topic                | topic_pkey                              | CREATE UNIQUE INDEX topic_pkey ON lesson_planner_fe.topic USING btree (topic_id)                                                            | 16 kB  |
| topic                | topic_subject_number_unique             | CREATE UNIQUE INDEX topic_subject_number_unique ON lesson_planner_fe.topic USING btree (subject_code, topic_number)                         | 16 kB  |

### Constraints
| Table                | Constraint                              | Type        | Column                  | Check Clause                                                                                                                                         |
|:---------------------|:----------------------------------------|:------------|:------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------|
| class                | 29115_29193_1_not_null                  | CHECK       | -                       | class_id IS NOT NULL                                                                                                                                 |
| class                | 29115_29193_2_not_null                  | CHECK       | -                       | school_id IS NOT NULL                                                                                                                                |
| class                | 29115_29193_3_not_null                  | CHECK       | -                       | teacher_id IS NOT NULL                                                                                                                               |
| class                | 29115_29193_4_not_null                  | CHECK       | -                       | name IS NOT NULL                                                                                                                                     |
| class                | class_pkey                              | PRIMARY KEY | class_id                | -                                                                                                                                                    |
| feedback             | 29115_29176_1_not_null                  | CHECK       | -                       | id IS NOT NULL                                                                                                                                       |
| feedback             | 29115_29176_2_not_null                  | CHECK       | -                       | teacher_id IS NOT NULL                                                                                                                               |
| feedback             | 29115_29176_3_not_null                  | CHECK       | -                       | rating IS NOT NULL                                                                                                                                   |
| feedback             | 29115_29176_6_not_null                  | CHECK       | -                       | lesson_plan_instance_id IS NOT NULL                                                                                                                  |
| feedback             | feedback_pkey                           | PRIMARY KEY | id                      | -                                                                                                                                                    |
| feedback             | unique_teacher_lesson_instance_feedback | UNIQUE      | lesson_plan_instance_id | -                                                                                                                                                    |
| feedback             | unique_teacher_lesson_instance_feedback | UNIQUE      | teacher_id              | -                                                                                                                                                    |
| lesson               | 29115_29256_1_not_null                  | CHECK       | -                       | lesson_id IS NOT NULL                                                                                                                                |
| lesson               | 29115_29256_2_not_null                  | CHECK       | -                       | topic_id IS NOT NULL                                                                                                                                 |
| lesson               | 29115_29256_3_not_null                  | CHECK       | -                       | subject_code IS NOT NULL                                                                                                                             |
| lesson               | 29115_29256_4_not_null                  | CHECK       | -                       | title IS NOT NULL                                                                                                                                    |
| lesson               | 29115_29256_6_not_null                  | CHECK       | -                       | lesson_number IS NOT NULL                                                                                                                            |
| lesson               | lesson_pkey_1                           | PRIMARY KEY | lesson_id               | -                                                                                                                                                    |
| lesson               | lesson_topic_number_unique_1            | UNIQUE      | lesson_number           | -                                                                                                                                                    |
| lesson               | lesson_topic_number_unique_1            | UNIQUE      | topic_id                | -                                                                                                                                                    |
| lesson_plan          | 29115_29206_14_not_null                 | CHECK       | -                       | shared_with_school IS NOT NULL                                                                                                                       |
| lesson_plan          | 29115_29206_1_not_null                  | CHECK       | -                       | id IS NOT NULL                                                                                                                                       |
| lesson_plan          | 29115_29206_2_not_null                  | CHECK       | -                       | lesson_id IS NOT NULL                                                                                                                                |
| lesson_plan          | 29115_29206_3_not_null                  | CHECK       | -                       | subject_code IS NOT NULL                                                                                                                             |
| lesson_plan          | 29115_29206_5_not_null                  | CHECK       | -                       | title IS NOT NULL                                                                                                                                    |
| lesson_plan          | 29115_29206_6_not_null                  | CHECK       | -                       | content IS NOT NULL                                                                                                                                  |
| lesson_plan          | lesson_plan_pkey                        | PRIMARY KEY | id                      | -                                                                                                                                                    |
| lesson_plan_instance | 29115_29223_1_not_null                  | CHECK       | -                       | instance_id IS NOT NULL                                                                                                                              |
| lesson_plan_instance | 29115_29223_2_not_null                  | CHECK       | -                       | class_id IS NOT NULL                                                                                                                                 |
| lesson_plan_instance | 29115_29223_5_not_null                  | CHECK       | -                       | teacher_id IS NOT NULL                                                                                                                               |
| lesson_plan_instance | 29115_29223_6_not_null                  | CHECK       | -                       | lesson_plan_id IS NOT NULL                                                                                                                           |
| lesson_plan_instance | 29115_29223_7_not_null                  | CHECK       | -                       | lesson_date IS NOT NULL                                                                                                                              |
| lesson_plan_instance | check_status                            | CHECK       | -                       | (((status)::text = ANY (ARRAY[('draft'::character varying)::text, ('published'::character varying)::text, ('completed'::character varying)::text]))) |
| lesson_plan_instance | lesson_plan_instance_pkey               | PRIMARY KEY | instance_id             | -                                                                                                                                                    |
| reflection           | 29115_29241_1_not_null                  | CHECK       | -                       | id IS NOT NULL                                                                                                                                       |
| reflection           | 29115_29241_2_not_null                  | CHECK       | -                       | teacher_id IS NOT NULL                                                                                                                               |
| reflection           | 29115_29241_4_not_null                  | CHECK       | -                       | lesson_plan_instance_id IS NOT NULL                                                                                                                  |
| reflection           | reflection_pkey                         | PRIMARY KEY | id                      | -                                                                                                                                                    |
| reflection           | uq_reflection_teacher_lesson            | UNIQUE      | lesson_plan_instance_id | -                                                                                                                                                    |
| reflection           | uq_reflection_teacher_lesson            | UNIQUE      | teacher_id              | -                                                                                                                                                    |
| school               | 29115_29133_1_not_null                  | CHECK       | -                       | school_id IS NOT NULL                                                                                                                                |
| school               | 29115_29133_2_not_null                  | CHECK       | -                       | name IS NOT NULL                                                                                                                                     |
| school               | school_pkey                             | PRIMARY KEY | school_id               | -                                                                                                                                                    |
| school               | school_name_unique                      | UNIQUE      | name                    | -                                                                                                                                                    |
| subject              | 29115_29271_1_not_null                  | CHECK       | -                       | subject_code IS NOT NULL                                                                                                                             |
| subject              | 29115_29271_2_not_null                  | CHECK       | -                       | name IS NOT NULL                                                                                                                                     |
| subject              | subject_pkey                            | PRIMARY KEY | subject_code            | -                                                                                                                                                    |
| teacher              | 29115_29146_1_not_null                  | CHECK       | -                       | teacher_id IS NOT NULL                                                                                                                               |
| teacher              | 29115_29146_2_not_null                  | CHECK       | -                       | school_id IS NOT NULL                                                                                                                                |
| teacher              | 29115_29146_3_not_null                  | CHECK       | -                       | email IS NOT NULL                                                                                                                                    |
| teacher              | 29115_29146_4_not_null                  | CHECK       | -                       | first_name IS NOT NULL                                                                                                                               |
| teacher              | 29115_29146_5_not_null                  | CHECK       | -                       | last_name IS NOT NULL                                                                                                                                |
| teacher              | teacher_pkey                            | PRIMARY KEY | teacher_id              | -                                                                                                                                                    |
| teacher              | teacher_email_unique                    | UNIQUE      | email                   | -                                                                                                                                                    |
| topic                | 29115_29161_1_not_null                  | CHECK       | -                       | topic_id IS NOT NULL                                                                                                                                 |
| topic                | 29115_29161_2_not_null                  | CHECK       | -                       | subject_code IS NOT NULL                                                                                                                             |
| topic                | 29115_29161_3_not_null                  | CHECK       | -                       | name IS NOT NULL                                                                                                                                     |
| topic                | 29115_29161_4_not_null                  | CHECK       | -                       | topic_number IS NOT NULL                                                                                                                             |
| topic                | topic_pkey                              | PRIMARY KEY | topic_id                | -                                                                                                                                                    |
| topic                | topic_subject_number_unique             | UNIQUE      | subject_code            | -                                                                                                                                                    |
| topic                | topic_subject_number_unique             | UNIQUE      | topic_number            | -                                                                                                                                                    |

## Schema: `practise_improve_pilot`

### Tables Overview
| Table Name           | Type       | Size       |   Rows | Description    |
|:---------------------|:-----------|:-----------|-------:|:---------------|
| answers              | BASE TABLE | 40 kB      |      0 | No description |
| chat_conversations   | BASE TABLE | 32 kB      |      0 | No description |
| chat_messages        | BASE TABLE | 40 kB      |      0 | No description |
| feedback             | BASE TABLE | 32 kB      |      0 | No description |
| lesson_metadata      | BASE TABLE | 8192 bytes |      0 | No description |
| lesson_progress      | BASE TABLE | 32 kB      |      0 | No description |
| lessons              | BASE TABLE | 80 kB      |     11 | No description |
| lessons_backup       | BASE TABLE | 8192 bytes |      0 | No description |
| passages             | BASE TABLE | 168 kB     |     32 | No description |
| progress             | BASE TABLE | 56 kB      |      0 | No description |
| prompt_groups        | BASE TABLE | 32 kB      |     16 | No description |
| prompts              | BASE TABLE | 96 kB      |     21 | No description |
| question_answer_keys | BASE TABLE | 24 kB      |      0 | No description |
| questions            | BASE TABLE | 144 kB     |     52 | No description |
| users                | BASE TABLE | 80 kB      |      6 | No description |

**Total Tables:** 15
**Total Rows:** 138

### Table: `answers`
| Metric      | Value   |
|:------------|:--------|
| Size        | 40 kB   |
| Live Tuples | 0       |
| Dead Tuples | 0       |
| Inserts     | 0       |
| Updates     | 0       |
| Deletes     | 0       |

#### Columns
| Column                | Type                        | Constraints   | Default            | Description   |
|:----------------------|:----------------------------|:--------------|:-------------------|:--------------|
| id                    | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| user_id               | uuid                        | FK | NOT NULL | -                  | -             |
| question_id           | uuid                        | NOT NULL      | -                  | -             |
| answer_text           | text                        | -             | -                  | -             |
| selected_option_index | integer(32)                 | -             | -                  | -             |
| score                 | numeric(5,2)                | -             | -                  | -             |
| max_possible_score    | integer(32)                 | NOT NULL      | 10                 | -             |
| is_evaluated          | boolean                     | NOT NULL      | false              | -             |
| evaluated_at          | timestamp without time zone | -             | -                  | -             |
| time_spent_seconds    | integer(32)                 | -             | -                  | -             |
| submitted_at          | timestamp without time zone | NOT NULL      | CURRENT_TIMESTAMP  | -             |

#### Data Quality Analysis
⚠️ Table is empty

### Table: `chat_conversations`
| Metric      | Value   |
|:------------|:--------|
| Size        | 32 kB   |
| Live Tuples | 0       |
| Dead Tuples | 0       |
| Inserts     | 0       |
| Updates     | 0       |
| Deletes     | 0       |

#### Columns
| Column     | Type                        | Constraints   | Default            | Description   |
|:-----------|:----------------------------|:--------------|:-------------------|:--------------|
| id         | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| user_id    | uuid                        | FK | NOT NULL | -                  | -             |
| lesson_id  | uuid                        | NOT NULL      | -                  | -             |
| is_active  | boolean                     | NOT NULL      | true               | -             |
| started_at | timestamp without time zone | NOT NULL      | CURRENT_TIMESTAMP  | -             |
| ended_at   | timestamp without time zone | -             | -                  | -             |

#### Data Quality Analysis
⚠️ Table is empty

### Table: `chat_messages`
| Metric      | Value   |
|:------------|:--------|
| Size        | 40 kB   |
| Live Tuples | 0       |
| Dead Tuples | 0       |
| Inserts     | 0       |
| Updates     | 0       |
| Deletes     | 0       |

#### Columns
| Column          | Type                        | Constraints   | Default            | Description   |
|:----------------|:----------------------------|:--------------|:-------------------|:--------------|
| id              | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| conversation_id | uuid                        | FK | NOT NULL | -                  | -             |
| sender          | USER-DEFINED                | NOT NULL      | -                  | -             |
| message_type    | USER-DEFINED                | NOT NULL      | -                  | -             |
| message_text    | text                        | -             | -                  | -             |
| passage_id      | uuid                        | -             | -                  | -             |
| question_id     | uuid                        | -             | -                  | -             |
| answer_id       | uuid                        | FK            | -                  | -             |
| feedback_id     | uuid                        | FK            | -                  | -             |
| message_order   | integer(32)                 | NOT NULL      | -                  | -             |
| created_at      | timestamp without time zone | NOT NULL      | CURRENT_TIMESTAMP  | -             |

#### Data Quality Analysis
⚠️ Table is empty

### Table: `feedback`
| Metric      | Value   |
|:------------|:--------|
| Size        | 32 kB   |
| Live Tuples | 0       |
| Dead Tuples | 0       |
| Inserts     | 0       |
| Updates     | 0       |
| Deletes     | 0       |

#### Columns
| Column           | Type                        | Constraints   | Default            | Description   |
|:-----------------|:----------------------------|:--------------|:-------------------|:--------------|
| id               | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| id               | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| id               | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| id               | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| answer_id        | uuid                        | FK | NOT NULL | -                  | -             |
| answer_id        | uuid                        | FK | NOT NULL | -                  | -             |
| feedback_text    | text                        | NOT NULL      | -                  | -             |
| feedback_text    | text                        | NOT NULL      | -                  | -             |
| score            | numeric(5,2)                | -             | -                  | -             |
| score            | numeric(5,2)                | -             | -                  | -             |
| corrective_steps | text                        | -             | -                  | -             |
| corrective_steps | text                        | -             | -                  | -             |
| prompt_id        | uuid                        | FK            | -                  | -             |
| prompt_id        | uuid                        | FK            | -                  | -             |
| generated_by     | text                        | -             | -                  | -             |
| generated_by     | text                        | -             | -                  | -             |
| is_helpful       | boolean                     | -             | -                  | -             |
| is_helpful       | boolean                     | -             | -                  | -             |
| created_at       | timestamp without time zone | NOT NULL      | CURRENT_TIMESTAMP  | -             |
| created_at       | timestamp without time zone | NOT NULL      | CURRENT_TIMESTAMP  | -             |
| updated_at       | timestamp without time zone | NOT NULL      | CURRENT_TIMESTAMP  | -             |
| updated_at       | timestamp without time zone | NOT NULL      | CURRENT_TIMESTAMP  | -             |

#### Data Quality Analysis
⚠️ Table is empty

### Table: `lesson_metadata`
| Metric      | Value      |
|:------------|:-----------|
| Size        | 8192 bytes |
| Live Tuples | 0          |
| Dead Tuples | 0          |
| Inserts     | 0          |
| Updates     | 0          |
| Deletes     | 0          |

#### Columns
| Column                  | Type                        | Constraints   | Default                                                             | Description   |
|:------------------------|:----------------------------|:--------------|:--------------------------------------------------------------------|:--------------|
| id                      | integer(32)                 | PK | NOT NULL | nextval('practise_improve_pilot.lesson_metadata_id_seq1'::regclass) | -             |
| version                 | character varying(50)       | NOT NULL      | -                                                                   | -             |
| last_updated            | timestamp without time zone | -             | CURRENT_TIMESTAMP                                                   | -             |
| content_approval_status | character varying(20)       | -             | 'approved'::character varying                                       | -             |
| created_at              | timestamp without time zone | -             | CURRENT_TIMESTAMP                                                   | -             |

#### Data Quality Analysis
⚠️ Table is empty

### Table: `lesson_progress`
| Metric      | Value   |
|:------------|:--------|
| Size        | 32 kB   |
| Live Tuples | 0       |
| Dead Tuples | 0       |
| Inserts     | 0       |
| Updates     | 0       |
| Deletes     | 0       |

#### Columns
| Column             | Type                        | Constraints   | Default                                             | Description   |
|:-------------------|:----------------------------|:--------------|:----------------------------------------------------|:--------------|
| id                 | uuid                        | PK | NOT NULL | uuid_generate_v4()                                  | -             |
| user_id            | uuid                        | FK | NOT NULL | -                                                   | -             |
| lesson_id          | uuid                        | NOT NULL      | -                                                   | -             |
| status             | USER-DEFINED                | NOT NULL      | 'not_started'::practise_improve_pilot.lesson_status | -             |
| overall_score      | numeric(5,2)                | -             | -                                                   | -             |
| questions_answered | integer(32)                 | NOT NULL      | 0                                                   | -             |
| questions_correct  | integer(32)                 | NOT NULL      | 0                                                   | -             |
| time_spent_seconds | integer(32)                 | -             | 0                                                   | -             |
| started_at         | timestamp without time zone | -             | -                                                   | -             |
| completed_at       | timestamp without time zone | -             | -                                                   | -             |
| last_updated       | timestamp without time zone | NOT NULL      | CURRENT_TIMESTAMP                                   | -             |

#### Data Quality Analysis
⚠️ Table is empty

### Table: `lessons`
| Metric      | Value   |
|:------------|:--------|
| Size        | 80 kB   |
| Live Tuples | 11      |
| Dead Tuples | 4       |
| Inserts     | 11      |
| Updates     | 4       |
| Deletes     | 0       |

#### Columns
| Column                   | Type                        | Constraints   | Default                                                     | Description   |
|:-------------------------|:----------------------------|:--------------|:------------------------------------------------------------|:--------------|
| id                       | integer(32)                 | PK | NOT NULL | nextval('practise_improve_pilot.lessons_id_seq1'::regclass) | -             |
| title                    | character varying(255)      | NOT NULL      | -                                                           | -             |
| proficiency_level        | character varying(20)       | NOT NULL      | -                                                           | -             |
| topic                    | character varying(100)      | NOT NULL      | -                                                           | -             |
| summary                  | text                        | NOT NULL      | -                                                           | -             |
| estimated_duration       | integer(32)                 | -             | -                                                           | -             |
| approval_status          | character varying(20)       | -             | 'approved'::character varying                               | -             |
| welcome_message          | text                        | -             | -                                                           | -             |
| introduction             | text                        | -             | -                                                           | -             |
| scoring_total_points     | integer(32)                 | -             | 0                                                           | -             |
| scoring_passing_score    | integer(32)                 | -             | 0                                                           | -             |
| scoring_method           | character varying(20)       | -             | 'points'::character varying                                 | -             |
| scoring_retry_allowed    | boolean                     | -             | true                                                        | -             |
| scoring_show_score_after | character varying(20)       | -             | 'lesson_complete'::character varying                        | -             |
| tags                     | jsonb                       | -             | -                                                           | -             |
| approved_by              | character varying(100)      | -             | -                                                           | -             |
| approved_at              | timestamp without time zone | -             | -                                                           | -             |
| created_at               | timestamp without time zone | -             | CURRENT_TIMESTAMP                                           | -             |
| updated_at               | timestamp without time zone | -             | CURRENT_TIMESTAMP                                           | -             |
| name                     | character varying(255)      | -             | -                                                           | -             |
| description              | text                        | -             | -                                                           | -             |
| text                     | text                        | -             | -                                                           | -             |
| completed                | boolean                     | -             | false                                                       | -             |

#### Data Quality Analysis
⚠️ Column 'topic' has 11 empty strings
⚠️ Column 'summary' has 4 empty strings

### Table: `lessons_backup`
| Metric      | Value      |
|:------------|:-----------|
| Size        | 8192 bytes |
| Live Tuples | 0          |
| Dead Tuples | 0          |
| Inserts     | 0          |
| Updates     | 0          |
| Deletes     | 0          |

#### Columns
| Column                     | Type                        | Constraints   | Default   | Description   |
|:---------------------------|:----------------------------|:--------------|:----------|:--------------|
| id                         | uuid                        | -             | -         | -             |
| title                      | character varying(255)      | -             | -         | -             |
| summary                    | text                        | -             | -         | -             |
| proficiency_level          | USER-DEFINED                | -             | -         | -             |
| topic                      | character varying(100)      | -             | -         | -             |
| estimated_duration_minutes | integer(32)                 | -             | -         | -             |
| is_active                  | boolean                     | -             | -         | -             |
| created_by                 | uuid                        | -             | -         | -             |
| created_at                 | timestamp without time zone | -             | -         | -             |
| updated_at                 | timestamp without time zone | -             | -         | -             |

#### Data Quality Analysis
⚠️ Table is empty

### Table: `passages`
| Metric      | Value   |
|:------------|:--------|
| Size        | 168 kB  |
| Live Tuples | 32      |
| Dead Tuples | 14      |
| Inserts     | 32      |
| Updates     | 37      |
| Deletes     | 0       |

#### Columns
| Column          | Type                        | Constraints   | Default                       | Description   |
|:----------------|:----------------------------|:--------------|:------------------------------|:--------------|
| id              | uuid                        | PK | NOT NULL | uuid_generate_v4()            | -             |
| lesson_id       | integer(32)                 | FK | NOT NULL | -                             | -             |
| title           | character varying(255)      | -             | -                             | -             |
| content         | text                        | NOT NULL      | -                             | -             |
| word_count      | integer(32)                 | -             | -                             | -             |
| reading_level   | character varying(50)       | -             | -                             | -             |
| approval_status | character varying(20)       | -             | 'approved'::character varying | -             |
| source          | character varying(255)      | -             | -                             | -             |
| sort_order      | integer(32)                 | -             | 0                             | -             |
| created_at      | timestamp without time zone | -             | CURRENT_TIMESTAMP             | -             |
| updated_at      | timestamp without time zone | -             | CURRENT_TIMESTAMP             | -             |
| prompt_id       | uuid                        | FK            | -                             | -             |
| generated_by    | uuid                        | FK            | -                             | -             |
| model_name      | character varying(100)      | -             | -                             | -             |
| temperature     | numeric(3,2)                | -             | -                             | -             |
| review_comments | text                        | -             | -                             | -             |
| approved_by     | uuid                        | FK            | -                             | -             |

#### Data Quality Analysis
✅ No data quality issues detected

### Table: `progress`
| Metric      | Value   |
|:------------|:--------|
| Size        | 56 kB   |
| Live Tuples | 0       |
| Dead Tuples | 0       |
| Inserts     | 0       |
| Updates     | 0       |
| Deletes     | 0       |

#### Columns
| Column          | Type                        | Constraints   | Default                                                      | Description   |
|:----------------|:----------------------------|:--------------|:-------------------------------------------------------------|:--------------|
| id              | integer(32)                 | PK | NOT NULL | nextval('practise_improve_pilot.progress_id_seq1'::regclass) | -             |
| user_id         | character varying(100)      | NOT NULL      | -                                                            | -             |
| lesson_id       | integer(32)                 | FK | NOT NULL | -                                                            | -             |
| status          | character varying(20)       | -             | 'in_progress'::character varying                             | -             |
| score           | integer(32)                 | -             | 0                                                            | -             |
| completed_at    | timestamp without time zone | -             | -                                                            | -             |
| time_spent      | integer(32)                 | -             | -                                                            | -             |
| attempt_number  | integer(32)                 | -             | 1                                                            | -             |
| question_scores | jsonb                       | -             | -                                                            | -             |
| created_at      | timestamp without time zone | -             | CURRENT_TIMESTAMP                                            | -             |
| updated_at      | timestamp without time zone | -             | CURRENT_TIMESTAMP                                            | -             |

#### Data Quality Analysis
⚠️ Table is empty

### Table: `prompt_groups`
| Metric      | Value   |
|:------------|:--------|
| Size        | 32 kB   |
| Live Tuples | 16      |
| Dead Tuples | 1       |
| Inserts     | 17      |
| Updates     | 0       |
| Deletes     | 1       |

#### Columns
| Column      | Type                        | Constraints   | Default            | Description   |
|:------------|:----------------------------|:--------------|:-------------------|:--------------|
| id          | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| category    | USER-DEFINED                | NOT NULL      | -                  | -             |
| title       | character varying(255)      | NOT NULL      | -                  | -             |
| description | text                        | -             | -                  | -             |
| is_active   | boolean                     | NOT NULL      | true               | -             |
| created_at  | timestamp without time zone | NOT NULL      | CURRENT_TIMESTAMP  | -             |
| updated_at  | timestamp without time zone | NOT NULL      | CURRENT_TIMESTAMP  | -             |

#### Data Quality Analysis
✅ No data quality issues detected

### Table: `prompts`
| Metric      | Value   |
|:------------|:--------|
| Size        | 96 kB   |
| Live Tuples | 21      |
| Dead Tuples | 10      |
| Inserts     | 21      |
| Updates     | 15      |
| Deletes     | 0       |

#### Columns
| Column     | Type                        | Constraints   | Default            | Description   |
|:-----------|:----------------------------|:--------------|:-------------------|:--------------|
| id         | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| group_id   | uuid                        | FK | NOT NULL | -                  | -             |
| content    | text                        | NOT NULL      | -                  | -             |
| version    | integer(32)                 | NOT NULL      | 1                  | -             |
| created_by | uuid                        | FK            | -                  | -             |
| is_active  | boolean                     | NOT NULL      | true               | -             |
| created_at | timestamp without time zone | NOT NULL      | CURRENT_TIMESTAMP  | -             |
| updated_at | timestamp without time zone | NOT NULL      | CURRENT_TIMESTAMP  | -             |

#### Data Quality Analysis
✅ No data quality issues detected

### Table: `question_answer_keys`
| Metric      | Value   |
|:------------|:--------|
| Size        | 24 kB   |
| Live Tuples | 0       |
| Dead Tuples | 0       |
| Inserts     | 0       |
| Updates     | 0       |
| Deletes     | 0       |

#### Columns
| Column               | Type                        | Constraints   | Default            | Description   |
|:---------------------|:----------------------------|:--------------|:-------------------|:--------------|
| id                   | uuid                        | PK | NOT NULL | uuid_generate_v4() | -             |
| question_id          | uuid                        | NOT NULL      | -                  | -             |
| answer_text          | text                        | -             | -                  | -             |
| explanation          | text                        | -             | -                  | -             |
| correct_option_index | integer(32)                 | -             | -                  | -             |
| keywords             | ARRAY                       | -             | -                  | -             |
| created_at           | timestamp without time zone | NOT NULL      | CURRENT_TIMESTAMP  | -             |
| updated_at           | timestamp without time zone | NOT NULL      | CURRENT_TIMESTAMP  | -             |

#### Data Quality Analysis
⚠️ Table is empty

### Table: `questions`
| Metric      | Value   |
|:------------|:--------|
| Size        | 144 kB  |
| Live Tuples | 52      |
| Dead Tuples | 3       |
| Inserts     | 52      |
| Updates     | 47      |
| Deletes     | 0       |

#### Columns
| Column                    | Type                        | Constraints   | Default                                                       | Description   |
|:--------------------------|:----------------------------|:--------------|:--------------------------------------------------------------|:--------------|
| id                        | integer(32)                 | PK | NOT NULL | nextval('practise_improve_pilot.questions_id_seq1'::regclass) | -             |
| lesson_id                 | integer(32)                 | FK | NOT NULL | -                                                             | -             |
| question_id               | character varying(50)       | NOT NULL      | -                                                             | -             |
| passage_id                | character varying(50)       | -             | -                                                             | -             |
| question_text             | text                        | NOT NULL      | -                                                             | -             |
| question_type             | character varying(20)       | NOT NULL      | -                                                             | -             |
| options                   | jsonb                       | -             | -                                                             | -             |
| correct_answer_index      | integer(32)                 | -             | -                                                             | -             |
| correct_answer            | text                        | -             | -                                                             | -             |
| acceptable_answers        | jsonb                       | -             | -                                                             | -             |
| feedback_correct          | text                        | -             | -                                                             | -             |
| feedback_incorrect        | text                        | -             | -                                                             | -             |
| feedback_corrective_steps | jsonb                       | -             | -                                                             | -             |
| feedback_explanation      | text                        | -             | -                                                             | -             |
| word_limit                | integer(32)                 | -             | -                                                             | -             |
| placeholder               | text                        | -             | -                                                             | -             |
| points                    | integer(32)                 | -             | 1                                                             | -             |
| approval_status           | character varying(20)       | -             | 'approved'::character varying                                 | -             |
| sort_order                | integer(32)                 | -             | 0                                                             | -             |
| created_at                | timestamp without time zone | -             | CURRENT_TIMESTAMP                                             | -             |
| updated_at                | timestamp without time zone | -             | CURRENT_TIMESTAMP                                             | -             |
| model_name                | character varying(100)      | -             | -                                                             | -             |
| temperature               | numeric(3,2)                | -             | -                                                             | -             |
| prompt_id                 | uuid                        | FK            | -                                                             | -             |
| question_focus            | character varying           | -             | -                                                             | -             |

#### Data Quality Analysis
✅ No data quality issues detected

### Table: `users`
| Metric      | Value   |
|:------------|:--------|
| Size        | 80 kB   |
| Live Tuples | 6       |
| Dead Tuples | 0       |
| Inserts     | 6       |
| Updates     | 0       |
| Deletes     | 0       |

#### Columns
| Column            | Type                        | Constraints   | Default                                     | Description   |
|:------------------|:----------------------------|:--------------|:--------------------------------------------|:--------------|
| id                | uuid                        | PK | NOT NULL | uuid_generate_v4()                          | -             |
| email             | character varying(255)      | NOT NULL      | -                                           | -             |
| password_hash     | character varying(255)      | NOT NULL      | -                                           | -             |
| name              | character varying(100)      | NOT NULL      | -                                           | -             |
| role              | USER-DEFINED                | NOT NULL      | 'student'::practise_improve_pilot.user_role | -             |
| proficiency_level | USER-DEFINED                | -             | -                                           | -             |
| created_at        | timestamp without time zone | NOT NULL      | CURRENT_TIMESTAMP                           | -             |
| updated_at        | timestamp without time zone | NOT NULL      | CURRENT_TIMESTAMP                           | -             |

#### Data Quality Analysis
✅ No data quality issues detected

### Foreign Key Relationships
| Table              | Column          | References            | On Delete   | On Update   |
|:-------------------|:----------------|:----------------------|:------------|:------------|
| answers            | user_id         | users.id              | CASCADE     | NO ACTION   |
| chat_conversations | user_id         | users.id              | CASCADE     | NO ACTION   |
| chat_messages      | answer_id       | answers.id            | SET NULL    | NO ACTION   |
| chat_messages      | conversation_id | chat_conversations.id | CASCADE     | NO ACTION   |
| chat_messages      | feedback_id     | feedback.id           | SET NULL    | NO ACTION   |
| feedback           | answer_id       | answers.id            | CASCADE     | NO ACTION   |
| feedback           | prompt_id       | prompts.id            | SET NULL    | NO ACTION   |
| lesson_progress    | user_id         | users.id              | CASCADE     | NO ACTION   |
| passages           | lesson_id       | lessons.id            | CASCADE     | NO ACTION   |
| passages           | approved_by     | users.id              | SET NULL    | NO ACTION   |
| passages           | generated_by    | users.id              | SET NULL    | NO ACTION   |
| passages           | prompt_id       | prompts.id            | SET NULL    | NO ACTION   |
| progress           | lesson_id       | lessons.id            | CASCADE     | NO ACTION   |
| prompts            | created_by      | users.id              | SET NULL    | NO ACTION   |
| prompts            | group_id        | prompt_groups.id      | CASCADE     | NO ACTION   |
| questions          | lesson_id       | lessons.id            | CASCADE     | NO ACTION   |
| questions          | prompt_id       | prompts.id            | SET NULL    | NO ACTION   |

### Indexes
| Table                | Index Name                                      | Definition                                                                                                                                               | Size       |
|:---------------------|:------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------|
| answers              | answers_pkey                                    | CREATE UNIQUE INDEX answers_pkey ON practise_improve_pilot.answers USING btree (id)                                                                      | 8192 bytes |
| answers              | answers_user_id_question_id_key                 | CREATE UNIQUE INDEX answers_user_id_question_id_key ON practise_improve_pilot.answers USING btree (user_id, question_id)                                 | 8192 bytes |
| answers              | idx_answers_evaluated                           | CREATE INDEX idx_answers_evaluated ON practise_improve_pilot.answers USING btree (is_evaluated, evaluated_at)                                            | 8192 bytes |
| answers              | idx_answers_user_question                       | CREATE INDEX idx_answers_user_question ON practise_improve_pilot.answers USING btree (user_id, question_id)                                              | 8192 bytes |
| chat_conversations   | chat_conversations_pkey                         | CREATE UNIQUE INDEX chat_conversations_pkey ON practise_improve_pilot.chat_conversations USING btree (id)                                                | 8192 bytes |
| chat_conversations   | chat_conversations_user_id_lesson_id_key        | CREATE UNIQUE INDEX chat_conversations_user_id_lesson_id_key ON practise_improve_pilot.chat_conversations USING btree (user_id, lesson_id)               | 8192 bytes |
| chat_conversations   | idx_chat_conversations_user_lesson              | CREATE INDEX idx_chat_conversations_user_lesson ON practise_improve_pilot.chat_conversations USING btree (user_id, lesson_id)                            | 8192 bytes |
| chat_conversations   | idx_conversations_active                        | CREATE INDEX idx_conversations_active ON practise_improve_pilot.chat_conversations USING btree (user_id) WHERE (is_active = true)                        | 8192 bytes |
| chat_messages        | chat_messages_conversation_id_message_order_key | CREATE UNIQUE INDEX chat_messages_conversation_id_message_order_key ON practise_improve_pilot.chat_messages USING btree (conversation_id, message_order) | 8192 bytes |
| chat_messages        | chat_messages_pkey                              | CREATE UNIQUE INDEX chat_messages_pkey ON practise_improve_pilot.chat_messages USING btree (id)                                                          | 8192 bytes |
| chat_messages        | idx_chat_messages_conversation_order            | CREATE INDEX idx_chat_messages_conversation_order ON practise_improve_pilot.chat_messages USING btree (conversation_id, message_order)                   | 8192 bytes |
| chat_messages        | idx_chat_messages_type                          | CREATE INDEX idx_chat_messages_type ON practise_improve_pilot.chat_messages USING btree (message_type)                                                   | 8192 bytes |
| feedback             | feedback_answer_id_key                          | CREATE UNIQUE INDEX feedback_answer_id_key ON practise_improve_pilot.feedback USING btree (answer_id)                                                    | 8192 bytes |
| feedback             | feedback_pkey                                   | CREATE UNIQUE INDEX feedback_pkey ON practise_improve_pilot.feedback USING btree (id)                                                                    | 8192 bytes |
| feedback             | idx_feedback_answer_id                          | CREATE INDEX idx_feedback_answer_id ON practise_improve_pilot.feedback USING btree (answer_id)                                                           | 8192 bytes |
| lesson_metadata      | lesson_metadata_pkey                            | CREATE UNIQUE INDEX lesson_metadata_pkey ON practise_improve_pilot.lesson_metadata USING btree (id)                                                      | 8192 bytes |
| lesson_progress      | idx_lesson_progress_status                      | CREATE INDEX idx_lesson_progress_status ON practise_improve_pilot.lesson_progress USING btree (status)                                                   | 8192 bytes |
| lesson_progress      | idx_lesson_progress_user_id                     | CREATE INDEX idx_lesson_progress_user_id ON practise_improve_pilot.lesson_progress USING btree (user_id)                                                 | 8192 bytes |
| lesson_progress      | lesson_progress_pkey                            | CREATE UNIQUE INDEX lesson_progress_pkey ON practise_improve_pilot.lesson_progress USING btree (id)                                                      | 8192 bytes |
| lesson_progress      | lesson_progress_user_id_lesson_id_key           | CREATE UNIQUE INDEX lesson_progress_user_id_lesson_id_key ON practise_improve_pilot.lesson_progress USING btree (user_id, lesson_id)                     | 8192 bytes |
| lessons              | idx_lessons_approval                            | CREATE INDEX idx_lessons_approval ON practise_improve_pilot.lessons USING btree (approval_status)                                                        | 16 kB      |
| lessons              | idx_lessons_proficiency                         | CREATE INDEX idx_lessons_proficiency ON practise_improve_pilot.lessons USING btree (proficiency_level)                                                   | 16 kB      |
| lessons              | idx_lessons_topic                               | CREATE INDEX idx_lessons_topic ON practise_improve_pilot.lessons USING btree (topic)                                                                     | 16 kB      |
| lessons              | lessons_pkey                                    | CREATE UNIQUE INDEX lessons_pkey ON practise_improve_pilot.lessons USING btree (id)                                                                      | 16 kB      |
| passages             | idx_passages_lesson_id                          | CREATE INDEX idx_passages_lesson_id ON practise_improve_pilot.passages USING btree (lesson_id)                                                           | 16 kB      |
| passages             | idx_passages_lesson_order                       | CREATE INDEX idx_passages_lesson_order ON practise_improve_pilot.passages USING btree (lesson_id, sort_order)                                            | 16 kB      |
| passages             | passages_pkey                                   | CREATE UNIQUE INDEX passages_pkey ON practise_improve_pilot.passages USING btree (id)                                                                    | 16 kB      |
| progress             | idx_progress_lesson_id                          | CREATE INDEX idx_progress_lesson_id ON practise_improve_pilot.progress USING btree (lesson_id)                                                           | 8192 bytes |
| progress             | idx_progress_status                             | CREATE INDEX idx_progress_status ON practise_improve_pilot.progress USING btree (status)                                                                 | 8192 bytes |
| progress             | idx_progress_user_id                            | CREATE INDEX idx_progress_user_id ON practise_improve_pilot.progress USING btree (user_id)                                                               | 8192 bytes |
| progress             | idx_progress_user_lesson                        | CREATE INDEX idx_progress_user_lesson ON practise_improve_pilot.progress USING btree (user_id, lesson_id)                                                | 8192 bytes |
| progress             | progress_pkey                                   | CREATE UNIQUE INDEX progress_pkey ON practise_improve_pilot.progress USING btree (id)                                                                    | 8192 bytes |
| progress             | unique_user_lesson_attempt                      | CREATE UNIQUE INDEX unique_user_lesson_attempt ON practise_improve_pilot.progress USING btree (user_id, lesson_id, attempt_number)                       | 8192 bytes |
| prompt_groups        | prompt_groups_pkey                              | CREATE UNIQUE INDEX prompt_groups_pkey ON practise_improve_pilot.prompt_groups USING btree (id)                                                          | 16 kB      |
| prompts              | idx_prompts_group_active                        | CREATE INDEX idx_prompts_group_active ON practise_improve_pilot.prompts USING btree (group_id, is_active)                                                | 16 kB      |
| prompts              | prompts_pkey                                    | CREATE UNIQUE INDEX prompts_pkey ON practise_improve_pilot.prompts USING btree (id)                                                                      | 16 kB      |
| prompts              | unique_active_version_per_group                 | CREATE UNIQUE INDEX unique_active_version_per_group ON practise_improve_pilot.prompts USING btree (group_id, version, is_active)                         | 16 kB      |
| question_answer_keys | question_answer_keys_pkey                       | CREATE UNIQUE INDEX question_answer_keys_pkey ON practise_improve_pilot.question_answer_keys USING btree (id)                                            | 8192 bytes |
| question_answer_keys | question_answer_keys_question_id_key            | CREATE UNIQUE INDEX question_answer_keys_question_id_key ON practise_improve_pilot.question_answer_keys USING btree (question_id)                        | 8192 bytes |
| questions            | idx_questions_lesson_id                         | CREATE INDEX idx_questions_lesson_id ON practise_improve_pilot.questions USING btree (lesson_id)                                                         | 16 kB      |
| questions            | idx_questions_lesson_order                      | CREATE INDEX idx_questions_lesson_order ON practise_improve_pilot.questions USING btree (lesson_id, sort_order)                                          | 16 kB      |
| questions            | idx_questions_type                              | CREATE INDEX idx_questions_type ON practise_improve_pilot.questions USING btree (question_type)                                                          | 16 kB      |
| questions            | questions_pkey                                  | CREATE UNIQUE INDEX questions_pkey ON practise_improve_pilot.questions USING btree (id)                                                                  | 16 kB      |
| questions            | unique_question_per_lesson                      | CREATE UNIQUE INDEX unique_question_per_lesson ON practise_improve_pilot.questions USING btree (lesson_id, question_id)                                  | 16 kB      |
| users                | idx_users_email                                 | CREATE INDEX idx_users_email ON practise_improve_pilot.users USING btree (email)                                                                         | 16 kB      |
| users                | idx_users_role                                  | CREATE INDEX idx_users_role ON practise_improve_pilot.users USING btree (role)                                                                           | 16 kB      |
| users                | users_email_key                                 | CREATE UNIQUE INDEX users_email_key ON practise_improve_pilot.users USING btree (email)                                                                  | 16 kB      |
| users                | users_pkey                                      | CREATE UNIQUE INDEX users_pkey ON practise_improve_pilot.users USING btree (id)                                                                          | 16 kB      |

### Constraints
| Table                | Constraint                                      | Type        | Column          | Check Clause                                                                                                                                                                                                                                                             |
|:---------------------|:------------------------------------------------|:------------|:----------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| answers              | 33163_33595_11_not_null                         | CHECK       | -               | submitted_at IS NOT NULL                                                                                                                                                                                                                                                 |
| answers              | 33163_33595_1_not_null                          | CHECK       | -               | id IS NOT NULL                                                                                                                                                                                                                                                           |
| answers              | 33163_33595_2_not_null                          | CHECK       | -               | user_id IS NOT NULL                                                                                                                                                                                                                                                      |
| answers              | 33163_33595_3_not_null                          | CHECK       | -               | question_id IS NOT NULL                                                                                                                                                                                                                                                  |
| answers              | 33163_33595_7_not_null                          | CHECK       | -               | max_possible_score IS NOT NULL                                                                                                                                                                                                                                           |
| answers              | 33163_33595_8_not_null                          | CHECK       | -               | is_evaluated IS NOT NULL                                                                                                                                                                                                                                                 |
| answers              | answers_score_check                             | CHECK       | -               | ((score >= (0)::numeric))                                                                                                                                                                                                                                                |
| answers              | answers_selected_option_index_check             | CHECK       | -               | ((selected_option_index >= 0))                                                                                                                                                                                                                                           |
| answers              | answers_time_spent_seconds_check                | CHECK       | -               | ((time_spent_seconds >= 0))                                                                                                                                                                                                                                              |
| answers              | answers_user_id_fkey                            | FOREIGN KEY | user_id         | -                                                                                                                                                                                                                                                                        |
| answers              | answers_pkey                                    | PRIMARY KEY | id              | -                                                                                                                                                                                                                                                                        |
| answers              | answers_user_id_question_id_key                 | UNIQUE      | user_id         | -                                                                                                                                                                                                                                                                        |
| answers              | answers_user_id_question_id_key                 | UNIQUE      | question_id     | -                                                                                                                                                                                                                                                                        |
| chat_conversations   | 33163_33618_1_not_null                          | CHECK       | -               | id IS NOT NULL                                                                                                                                                                                                                                                           |
| chat_conversations   | 33163_33618_2_not_null                          | CHECK       | -               | user_id IS NOT NULL                                                                                                                                                                                                                                                      |
| chat_conversations   | 33163_33618_3_not_null                          | CHECK       | -               | lesson_id IS NOT NULL                                                                                                                                                                                                                                                    |
| chat_conversations   | 33163_33618_4_not_null                          | CHECK       | -               | is_active IS NOT NULL                                                                                                                                                                                                                                                    |
| chat_conversations   | 33163_33618_5_not_null                          | CHECK       | -               | started_at IS NOT NULL                                                                                                                                                                                                                                                   |
| chat_conversations   | chat_conversations_check                        | CHECK       | -               | (((ended_at IS NULL) OR (ended_at >= started_at)))                                                                                                                                                                                                                       |
| chat_conversations   | chat_conversations_user_id_fkey                 | FOREIGN KEY | user_id         | -                                                                                                                                                                                                                                                                        |
| chat_conversations   | chat_conversations_pkey                         | PRIMARY KEY | id              | -                                                                                                                                                                                                                                                                        |
| chat_conversations   | chat_conversations_user_id_lesson_id_key        | UNIQUE      | user_id         | -                                                                                                                                                                                                                                                                        |
| chat_conversations   | chat_conversations_user_id_lesson_id_key        | UNIQUE      | lesson_id       | -                                                                                                                                                                                                                                                                        |
| chat_messages        | 33163_33816_10_not_null                         | CHECK       | -               | message_order IS NOT NULL                                                                                                                                                                                                                                                |
| chat_messages        | 33163_33816_11_not_null                         | CHECK       | -               | created_at IS NOT NULL                                                                                                                                                                                                                                                   |
| chat_messages        | 33163_33816_1_not_null                          | CHECK       | -               | id IS NOT NULL                                                                                                                                                                                                                                                           |
| chat_messages        | 33163_33816_2_not_null                          | CHECK       | -               | conversation_id IS NOT NULL                                                                                                                                                                                                                                              |
| chat_messages        | 33163_33816_3_not_null                          | CHECK       | -               | sender IS NOT NULL                                                                                                                                                                                                                                                       |
| chat_messages        | 33163_33816_4_not_null                          | CHECK       | -               | message_type IS NOT NULL                                                                                                                                                                                                                                                 |
| chat_messages        | chat_messages_message_order_check               | CHECK       | -               | ((message_order > 0))                                                                                                                                                                                                                                                    |
| chat_messages        | chat_messages_answer_id_fkey                    | FOREIGN KEY | answer_id       | -                                                                                                                                                                                                                                                                        |
| chat_messages        | chat_messages_conversation_id_fkey              | FOREIGN KEY | conversation_id | -                                                                                                                                                                                                                                                                        |
| chat_messages        | chat_messages_feedback_id_fkey                  | FOREIGN KEY | feedback_id     | -                                                                                                                                                                                                                                                                        |
| chat_messages        | chat_messages_pkey                              | PRIMARY KEY | id              | -                                                                                                                                                                                                                                                                        |
| chat_messages        | chat_messages_conversation_id_message_order_key | UNIQUE      | conversation_id | -                                                                                                                                                                                                                                                                        |
| chat_messages        | chat_messages_conversation_id_message_order_key | UNIQUE      | message_order   | -                                                                                                                                                                                                                                                                        |
| feedback             | 33163_33755_10_not_null                         | CHECK       | -               | updated_at IS NOT NULL                                                                                                                                                                                                                                                   |
| feedback             | 33163_33755_1_not_null                          | CHECK       | -               | id IS NOT NULL                                                                                                                                                                                                                                                           |
| feedback             | 33163_33755_2_not_null                          | CHECK       | -               | answer_id IS NOT NULL                                                                                                                                                                                                                                                    |
| feedback             | 33163_33755_3_not_null                          | CHECK       | -               | feedback_text IS NOT NULL                                                                                                                                                                                                                                                |
| feedback             | 33163_33755_9_not_null                          | CHECK       | -               | created_at IS NOT NULL                                                                                                                                                                                                                                                   |
| feedback             | feedback_feedback_text_check                    | CHECK       | -               | ((char_length(TRIM(BOTH FROM feedback_text)) > 0))                                                                                                                                                                                                                       |
| feedback             | feedback_score_check                            | CHECK       | -               | ((score >= (0)::numeric))                                                                                                                                                                                                                                                |
| feedback             | feedback_answer_id_fkey                         | FOREIGN KEY | answer_id       | -                                                                                                                                                                                                                                                                        |
| feedback             | feedback_prompt_id_fkey                         | FOREIGN KEY | prompt_id       | -                                                                                                                                                                                                                                                                        |
| feedback             | feedback_pkey                                   | PRIMARY KEY | id              | -                                                                                                                                                                                                                                                                        |
| feedback             | feedback_answer_id_key                          | UNIQUE      | answer_id       | -                                                                                                                                                                                                                                                                        |
| lesson_metadata      | 33163_33507_1_not_null                          | CHECK       | -               | id IS NOT NULL                                                                                                                                                                                                                                                           |
| lesson_metadata      | 33163_33507_2_not_null                          | CHECK       | -               | version IS NOT NULL                                                                                                                                                                                                                                                      |
| lesson_metadata      | valid_content_approval_status                   | CHECK       | -               | (((content_approval_status)::text = ANY (ARRAY[('approved'::character varying)::text, ('pending'::character varying)::text, ('draft'::character varying)::text])))                                                                                                       |
| lesson_metadata      | lesson_metadata_pkey                            | PRIMARY KEY | id              | -                                                                                                                                                                                                                                                                        |
| lesson_progress      | 33163_33636_11_not_null                         | CHECK       | -               | last_updated IS NOT NULL                                                                                                                                                                                                                                                 |
| lesson_progress      | 33163_33636_1_not_null                          | CHECK       | -               | id IS NOT NULL                                                                                                                                                                                                                                                           |
| lesson_progress      | 33163_33636_2_not_null                          | CHECK       | -               | user_id IS NOT NULL                                                                                                                                                                                                                                                      |
| lesson_progress      | 33163_33636_3_not_null                          | CHECK       | -               | lesson_id IS NOT NULL                                                                                                                                                                                                                                                    |
| lesson_progress      | 33163_33636_4_not_null                          | CHECK       | -               | status IS NOT NULL                                                                                                                                                                                                                                                       |
| lesson_progress      | 33163_33636_6_not_null                          | CHECK       | -               | questions_answered IS NOT NULL                                                                                                                                                                                                                                           |
| lesson_progress      | 33163_33636_7_not_null                          | CHECK       | -               | questions_correct IS NOT NULL                                                                                                                                                                                                                                            |
| lesson_progress      | lesson_progress_check                           | CHECK       | -               | ((questions_correct <= questions_answered))                                                                                                                                                                                                                              |
| lesson_progress      | lesson_progress_check1                          | CHECK       | -               | (((started_at IS NULL) OR (completed_at IS NULL) OR (completed_at >= started_at)))                                                                                                                                                                                       |
| lesson_progress      | lesson_progress_overall_score_check             | CHECK       | -               | (((overall_score >= (0)::numeric) AND (overall_score <= (100)::numeric)))                                                                                                                                                                                                |
| lesson_progress      | lesson_progress_questions_answered_check        | CHECK       | -               | ((questions_answered >= 0))                                                                                                                                                                                                                                              |
| lesson_progress      | lesson_progress_questions_correct_check         | CHECK       | -               | ((questions_correct >= 0))                                                                                                                                                                                                                                               |
| lesson_progress      | lesson_progress_time_spent_seconds_check        | CHECK       | -               | ((time_spent_seconds >= 0))                                                                                                                                                                                                                                              |
| lesson_progress      | lesson_progress_user_id_fkey                    | FOREIGN KEY | user_id         | -                                                                                                                                                                                                                                                                        |
| lesson_progress      | lesson_progress_pkey                            | PRIMARY KEY | id              | -                                                                                                                                                                                                                                                                        |
| lesson_progress      | lesson_progress_user_id_lesson_id_key           | UNIQUE      | user_id         | -                                                                                                                                                                                                                                                                        |
| lesson_progress      | lesson_progress_user_id_lesson_id_key           | UNIQUE      | lesson_id       | -                                                                                                                                                                                                                                                                        |
| lessons              | 33163_33518_1_not_null                          | CHECK       | -               | id IS NOT NULL                                                                                                                                                                                                                                                           |
| lessons              | 33163_33518_2_not_null                          | CHECK       | -               | title IS NOT NULL                                                                                                                                                                                                                                                        |
| lessons              | 33163_33518_3_not_null                          | CHECK       | -               | proficiency_level IS NOT NULL                                                                                                                                                                                                                                            |
| lessons              | 33163_33518_4_not_null                          | CHECK       | -               | topic IS NOT NULL                                                                                                                                                                                                                                                        |
| lessons              | 33163_33518_5_not_null                          | CHECK       | -               | summary IS NOT NULL                                                                                                                                                                                                                                                      |
| lessons              | valid_approval_status                           | CHECK       | -               | (((approval_status)::text = ANY (ARRAY[('approved'::character varying)::text, ('pending'::character varying)::text, ('draft'::character varying)::text])))                                                                                                               |
| lessons              | valid_duration                                  | CHECK       | -               | (((estimated_duration IS NULL) OR ((estimated_duration > 0) AND (estimated_duration <= 120))))                                                                                                                                                                           |
| lessons              | valid_proficiency_level                         | CHECK       | -               | (((proficiency_level)::text = ANY (ARRAY[('A1'::character varying)::text, ('A2'::character varying)::text, ('B1'::character varying)::text, ('B2'::character varying)::text, ('C1'::character varying)::text, ('C2'::character varying)::text])))                        |
| lessons              | valid_scoring_method                            | CHECK       | -               | (((scoring_method)::text = ANY (ARRAY[('points'::character varying)::text, ('percentage'::character varying)::text])))                                                                                                                                                   |
| lessons              | valid_show_score_after                          | CHECK       | -               | (((scoring_show_score_after)::text = ANY (ARRAY[('each_question'::character varying)::text, ('lesson_complete'::character varying)::text])))                                                                                                                             |
| lessons              | lessons_pkey                                    | PRIMARY KEY | id              | -                                                                                                                                                                                                                                                                        |
| passages             | 33163_33781_1_not_null                          | CHECK       | -               | id IS NOT NULL                                                                                                                                                                                                                                                           |
| passages             | 33163_33781_2_not_null                          | CHECK       | -               | lesson_id IS NOT NULL                                                                                                                                                                                                                                                    |
| passages             | 33163_33781_4_not_null                          | CHECK       | -               | content IS NOT NULL                                                                                                                                                                                                                                                      |
| passages             | valid_passage_approval_status                   | CHECK       | -               | (((approval_status)::text = ANY (ARRAY[('approved'::character varying)::text, ('pending'::character varying)::text, ('draft'::character varying)::text, ('rejected'::character varying)::text])))                                                                        |
| passages             | fk_passage_lesson_id                            | FOREIGN KEY | lesson_id       | -                                                                                                                                                                                                                                                                        |
| passages             | passages_approved_by_fkey                       | FOREIGN KEY | approved_by     | -                                                                                                                                                                                                                                                                        |
| passages             | passages_generated_by_fkey                      | FOREIGN KEY | generated_by    | -                                                                                                                                                                                                                                                                        |
| passages             | passages_prompt_id_fkey                         | FOREIGN KEY | prompt_id       | -                                                                                                                                                                                                                                                                        |
| passages             | passages_pkey                                   | PRIMARY KEY | id              | -                                                                                                                                                                                                                                                                        |
| progress             | 33163_33663_1_not_null                          | CHECK       | -               | id IS NOT NULL                                                                                                                                                                                                                                                           |
| progress             | 33163_33663_2_not_null                          | CHECK       | -               | user_id IS NOT NULL                                                                                                                                                                                                                                                      |
| progress             | 33163_33663_3_not_null                          | CHECK       | -               | lesson_id IS NOT NULL                                                                                                                                                                                                                                                    |
| progress             | valid_attempt_number                            | CHECK       | -               | ((attempt_number > 0))                                                                                                                                                                                                                                                   |
| progress             | valid_score                                     | CHECK       | -               | (((score >= 0) AND (score <= 100)))                                                                                                                                                                                                                                      |
| progress             | valid_status                                    | CHECK       | -               | (((status)::text = ANY (ARRAY[('in_progress'::character varying)::text, ('completed'::character varying)::text, ('failed'::character varying)::text])))                                                                                                                  |
| progress             | valid_time_spent                                | CHECK       | -               | (((time_spent IS NULL) OR (time_spent >= 0)))                                                                                                                                                                                                                            |
| progress             | fk_progress_lesson_id                           | FOREIGN KEY | lesson_id       | -                                                                                                                                                                                                                                                                        |
| progress             | progress_pkey                                   | PRIMARY KEY | id              | -                                                                                                                                                                                                                                                                        |
| progress             | unique_user_lesson_attempt                      | UNIQUE      | attempt_number  | -                                                                                                                                                                                                                                                                        |
| progress             | unique_user_lesson_attempt                      | UNIQUE      | lesson_id       | -                                                                                                                                                                                                                                                                        |
| progress             | unique_user_lesson_attempt                      | UNIQUE      | user_id         | -                                                                                                                                                                                                                                                                        |
| prompt_groups        | 33163_33548_1_not_null                          | CHECK       | -               | id IS NOT NULL                                                                                                                                                                                                                                                           |
| prompt_groups        | 33163_33548_2_not_null                          | CHECK       | -               | category IS NOT NULL                                                                                                                                                                                                                                                     |
| prompt_groups        | 33163_33548_3_not_null                          | CHECK       | -               | title IS NOT NULL                                                                                                                                                                                                                                                        |
| prompt_groups        | 33163_33548_5_not_null                          | CHECK       | -               | is_active IS NOT NULL                                                                                                                                                                                                                                                    |
| prompt_groups        | 33163_33548_6_not_null                          | CHECK       | -               | created_at IS NOT NULL                                                                                                                                                                                                                                                   |
| prompt_groups        | 33163_33548_7_not_null                          | CHECK       | -               | updated_at IS NOT NULL                                                                                                                                                                                                                                                   |
| prompt_groups        | prompt_groups_title_check                       | CHECK       | -               | ((char_length(TRIM(BOTH FROM title)) > 0))                                                                                                                                                                                                                               |
| prompt_groups        | prompt_groups_pkey                              | PRIMARY KEY | id              | -                                                                                                                                                                                                                                                                        |
| prompts              | 33163_33691_1_not_null                          | CHECK       | -               | id IS NOT NULL                                                                                                                                                                                                                                                           |
| prompts              | 33163_33691_2_not_null                          | CHECK       | -               | group_id IS NOT NULL                                                                                                                                                                                                                                                     |
| prompts              | 33163_33691_3_not_null                          | CHECK       | -               | content IS NOT NULL                                                                                                                                                                                                                                                      |
| prompts              | 33163_33691_4_not_null                          | CHECK       | -               | version IS NOT NULL                                                                                                                                                                                                                                                      |
| prompts              | 33163_33691_6_not_null                          | CHECK       | -               | is_active IS NOT NULL                                                                                                                                                                                                                                                    |
| prompts              | 33163_33691_7_not_null                          | CHECK       | -               | created_at IS NOT NULL                                                                                                                                                                                                                                                   |
| prompts              | 33163_33691_8_not_null                          | CHECK       | -               | updated_at IS NOT NULL                                                                                                                                                                                                                                                   |
| prompts              | prompts_content_check                           | CHECK       | -               | ((char_length(TRIM(BOTH FROM content)) > 0))                                                                                                                                                                                                                             |
| prompts              | prompts_version_check                           | CHECK       | -               | ((version > 0))                                                                                                                                                                                                                                                          |
| prompts              | prompts_created_by_fkey                         | FOREIGN KEY | created_by      | -                                                                                                                                                                                                                                                                        |
| prompts              | prompts_group_id_fkey                           | FOREIGN KEY | group_id        | -                                                                                                                                                                                                                                                                        |
| prompts              | prompts_pkey                                    | PRIMARY KEY | id              | -                                                                                                                                                                                                                                                                        |
| prompts              | unique_active_version_per_group                 | UNIQUE      | is_active       | -                                                                                                                                                                                                                                                                        |
| prompts              | unique_active_version_per_group                 | UNIQUE      | group_id        | -                                                                                                                                                                                                                                                                        |
| prompts              | unique_active_version_per_group                 | UNIQUE      | version         | -                                                                                                                                                                                                                                                                        |
| question_answer_keys | 33163_33562_1_not_null                          | CHECK       | -               | id IS NOT NULL                                                                                                                                                                                                                                                           |
| question_answer_keys | 33163_33562_2_not_null                          | CHECK       | -               | question_id IS NOT NULL                                                                                                                                                                                                                                                  |
| question_answer_keys | 33163_33562_7_not_null                          | CHECK       | -               | created_at IS NOT NULL                                                                                                                                                                                                                                                   |
| question_answer_keys | 33163_33562_8_not_null                          | CHECK       | -               | updated_at IS NOT NULL                                                                                                                                                                                                                                                   |
| question_answer_keys | question_answer_keys_correct_option_index_check | CHECK       | -               | ((correct_option_index >= 0))                                                                                                                                                                                                                                            |
| question_answer_keys | question_answer_keys_pkey                       | PRIMARY KEY | id              | -                                                                                                                                                                                                                                                                        |
| question_answer_keys | question_answer_keys_question_id_key            | UNIQUE      | question_id     | -                                                                                                                                                                                                                                                                        |
| questions            | 33163_33721_1_not_null                          | CHECK       | -               | id IS NOT NULL                                                                                                                                                                                                                                                           |
| questions            | 33163_33721_2_not_null                          | CHECK       | -               | lesson_id IS NOT NULL                                                                                                                                                                                                                                                    |
| questions            | 33163_33721_3_not_null                          | CHECK       | -               | question_id IS NOT NULL                                                                                                                                                                                                                                                  |
| questions            | 33163_33721_5_not_null                          | CHECK       | -               | question_text IS NOT NULL                                                                                                                                                                                                                                                |
| questions            | 33163_33721_6_not_null                          | CHECK       | -               | question_type IS NOT NULL                                                                                                                                                                                                                                                |
| questions            | valid_mcq_data                                  | CHECK       | -               | (((((question_type)::text = 'mcq'::text) AND (options IS NOT NULL) AND (jsonb_typeof(options) = 'array'::text) AND (jsonb_array_length(options) > 0) AND (correct_answer_index IS NOT NULL) AND (correct_answer_index >= 0)) OR ((question_type)::text <> 'mcq'::text))) |
| questions            | valid_points                                    | CHECK       | -               | ((points > 0))                                                                                                                                                                                                                                                           |
| questions            | valid_question_approval_status                  | CHECK       | -               | (((approval_status)::text = ANY (ARRAY[('approved'::character varying)::text, ('pending'::character varying)::text, ('draft'::character varying)::text, ('rejected'::character varying)::text])))                                                                        |
| questions            | valid_question_type                             | CHECK       | -               | (((question_type)::text = ANY (ARRAY[('mcq'::character varying)::text, ('short_answer'::character varying)::text, ('complete_sentence'::character varying)::text])))                                                                                                     |
| questions            | valid_text_answer                               | CHECK       | -               | (((((question_type)::text = ANY (ARRAY[('short_answer'::character varying)::text, ('complete_sentence'::character varying)::text])) AND (correct_answer IS NOT NULL) AND (length(TRIM(BOTH FROM correct_answer)) > 0)) OR ((question_type)::text = 'mcq'::text)))        |
| questions            | valid_word_limit                                | CHECK       | -               | (((word_limit IS NULL) OR ((word_limit > 0) AND (word_limit <= 500))))                                                                                                                                                                                                   |
| questions            | fk_question_lesson_id                           | FOREIGN KEY | lesson_id       | -                                                                                                                                                                                                                                                                        |
| questions            | questions_prompt_id_fkey                        | FOREIGN KEY | prompt_id       | -                                                                                                                                                                                                                                                                        |
| questions            | questions_pkey                                  | PRIMARY KEY | id              | -                                                                                                                                                                                                                                                                        |
| questions            | unique_question_per_lesson                      | UNIQUE      | question_id     | -                                                                                                                                                                                                                                                                        |
| questions            | unique_question_per_lesson                      | UNIQUE      | lesson_id       | -                                                                                                                                                                                                                                                                        |
| users                | 33163_33576_1_not_null                          | CHECK       | -               | id IS NOT NULL                                                                                                                                                                                                                                                           |
| users                | 33163_33576_2_not_null                          | CHECK       | -               | email IS NOT NULL                                                                                                                                                                                                                                                        |
| users                | 33163_33576_3_not_null                          | CHECK       | -               | password_hash IS NOT NULL                                                                                                                                                                                                                                                |
| users                | 33163_33576_4_not_null                          | CHECK       | -               | name IS NOT NULL                                                                                                                                                                                                                                                         |
| users                | 33163_33576_5_not_null                          | CHECK       | -               | role IS NOT NULL                                                                                                                                                                                                                                                         |
| users                | 33163_33576_7_not_null                          | CHECK       | -               | created_at IS NOT NULL                                                                                                                                                                                                                                                   |
| users                | 33163_33576_8_not_null                          | CHECK       | -               | updated_at IS NOT NULL                                                                                                                                                                                                                                                   |
| users                | users_email_check                               | CHECK       | -               | (((email)::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text))                                                                                                                                                                                            |
| users                | users_name_check                                | CHECK       | -               | ((char_length(TRIM(BOTH FROM name)) > 0))                                                                                                                                                                                                                                |
| users                | users_password_hash_check                       | CHECK       | -               | ((char_length((password_hash)::text) >= 60))                                                                                                                                                                                                                             |
| users                | users_pkey                                      | PRIMARY KEY | id              | -                                                                                                                                                                                                                                                                        |
| users                | users_email_key                                 | UNIQUE      | email           | -                                                                                                                                                                                                                                                                        |

## Schema: `public`

*No tables found in this schema.*

## Schema Analysis & Recommendations

### Critical Issues Found
⚠️ Table `lesson_planner_fe.feedback` has high dead tuple ratio (25.0%)
⚠️ Table `lesson_planner_fe.subject` has high dead tuple ratio (50.0%)
⚠️ Table `lesson_planner_fe.topic` has high dead tuple ratio (50.0%)
⚠️ Table `practise_improve_pilot.lessons` has high dead tuple ratio (26.7%)
❌ Table `practise_improve_pilot.lessons_backup` has no primary key
⚠️ Table `practise_improve_pilot.passages` has high dead tuple ratio (30.4%)
⚠️ Table `practise_improve_pilot.prompts` has high dead tuple ratio (32.3%)

### Recommendations
1. Consider running VACUUM on `lesson_planner_fe.feedback` to clean up dead tuples
2. Consider running VACUUM on `lesson_planner_fe.subject` to clean up dead tuples
3. Consider running VACUUM on `lesson_planner_fe.topic` to clean up dead tuples
4. Consider running VACUUM on `practise_improve_pilot.lessons` to clean up dead tuples
5. Add a primary key to `practise_improve_pilot.lessons_backup` for better performance and data integrity
6. Consider running VACUUM on `practise_improve_pilot.passages` to clean up dead tuples
7. Consider running VACUUM on `practise_improve_pilot.prompts` to clean up dead tuples

### Security Considerations
1. Ensure sensitive data columns are properly encrypted
2. Implement row-level security (RLS) where appropriate
3. Regular security audits of user permissions
4. Consider using database roles instead of individual user permissions

### Performance Considerations
1. Monitor and analyze slow queries regularly
2. Ensure proper indexing on frequently queried columns
3. Consider implementing connection pooling
4. Regular VACUUM and ANALYZE operations
5. Monitor database size and plan for scaling
