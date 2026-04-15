CREATE TABLE staging_github (
    repositories VARCHAR(255),
    stars_count INT,
    forks_count INT,
    issues_count INT,
    pull_requests INT,
    contributors INT,
    language VARCHAR(255)
    
);

CREATE TABLE staging_repository (
    name VARCHAR(255),
    stars_count INT,
    forks_count INT,
    watchers INT,
    pull_requests INT,
    primary_language VARCHAR(255),
    languages_used TEXT,
    commit_count DECIMAL(9,1),
    created_at TIMESTAMP,
    licence Vforks_count INT,
    watchers INT,
    pull_requests INT,
    primary_language VARCHAR(255),
    languages_used TEXT,
    commit_count DECIMAL(9,1),
    created_at TIMESTAMP,
    licenceARCHAR(255)
);

CREATE TABLE dim_language (
    language_id SERIAL PRIMARY KEY,
    language_name VARCHAR(255)
);

INSERT INTO dim_language (language_name)
SELECT DISTINCT language FROM staging_github
WHERE language IS NOT NULL;

CREATE TABLE dim_repository (
    repo_id SERIAL PRIMARY KEY,
    repo_name VARCHAR(255),
    license VARCHAR(255)
);

INSERT INTO dim_repository (repo_name, license)
SELECT DISTINCT name, licence 
FROM staging_repository;

CREATE TABLE dim_time (
    time_id SERIAL PRIMARY KEY,
    year INT,
    month INT,
    day INT
);

INSERT INTO dim_time(year, month, day)
SELECT DISTINCT
    EXTRACT(YEAR FROM created_at),
    EXTRACT(MONTH FROM created_at),
    EXTRACT(DAY FROM created_at)
FROM staging_repository
WHERE created_at IS NOT NULL;

CREATE TABLE dim_language_used (
    language_used_id SERIAL PRIMARY KEY,
    language_name VARCHAR(255)
);

INSERT INTO dim_language_used  (language_name)
SELECT DISTINCT unnest(string_to_array(languages_used, ',')) AS language_name
FROM staging_repository
WHERE languages_used IS NOT NULL;

CREATE TABLE fact_repo_activity (
    fact_id SERIAL PRIMARY KEY,
    repo_id INT REFERENCES dim_repository(repo_id),
    primary_language_id INT REFERENCES dim_language(language_id),
    time_id INT REFERENCES dim_time(time_id),
    stars_count INT,
    forks_count INT,
    watchers INT,
    issues_count INT,
    pull_requests INT,
    contributors INT,
    commit_count DECIMAL(9,1)
);

INSERT INTO fact_repo_activity (
    repo_id,
    primary_language_id,
    time_id,
    stars_count,
    forks_count,
    watchers,
    issues_count,
    pull_requests,
    contributors,
    commit_count
)
SELECT
    dr.repo_id,
    dl.language_id,
    dt.time_id,
    sr.stars_count,
    sr.forks_count,
    sr.watchers,
    sg.issues_count,
    sg.pull_requests,
    sg.contributors,
    sr.commit_count
FROM staging_repository sr
JOIN dim_repository dr
    ON sr.name = dr.repo_name
LEFT JOIN dim_language dl
    ON sr.primary_language = dl.language_name
LEFT JOIN dim_time dt
    ON EXTRACT(YEAR FROM sr.created_at) = dt.year
   AND EXTRACT(MONTH FROM sr.created_at) = dt.month
   AND EXTRACT(DAY FROM sr.created_at) = dt.day
LEFT JOIN staging_github sg
    ON sg.repositories = sr.name;
