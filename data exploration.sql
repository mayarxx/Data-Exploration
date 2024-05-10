select *
from PortfolioProject..CovidDeaths
where continent IS NOT NULL
order by 3,4;

select 
	location,
	date,
	population,
	total_cases,
	new_cases,
	total_deaths
from 
	PortfolioProject..CovidDeaths
where 
	continent IS NOT NULL
order by
	1,2;

--analyzing total cases vs total deaths
--shows likelihood of death if contracted covid in a specific country
select 
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 AS DeathPercentage
from 
	PortfolioProject..CovidDeaths
where 
	location = 'Egypt'
order by
	1,2;

--total cases vs population
--shows the percentage of population who got covid
select
	location,
	date,
	population,
	total_cases,
	(total_cases/population)*100 AS CasesPercentage
from
	PortfolioProject..CovidDeaths
--where location = 'Egypt'
order by
	1,2;

--Countries with highest infection rate compared to population
select 
	location,
	population,
	MAX(total_cases) AS highestInfectionRate,
	MAX((total_cases/population))*100 AS CasesPercentage
from
	PortfolioProject..CovidDeaths
--where location = 'Egypt'
group by
	location, population
order by
	CasesPercentage DESC;

--Countries with highest death count per population
select
	location,
	MAX(total_deaths) AS TotalDeathCount
from
	PortfolioProject..CovidDeaths
--where location = 'Egypt'
where
	continent IS NOT NULL
group by
	location
order by
	TotalDeathCount DESC;

--Countries with highest death rate compared to population
select
	location,
	population,
	MAX(total_deaths) AS TotalDeathCount,
	MAX((total_deaths/population))*100 AS DeathsPercentage
from 
	PortfolioProject..CovidDeaths
--where location = 'Egypt'
group by
	location, population
order by
	DeathsPercentage DESC;

--Breaking The Analysis By Continent

--Continents with highest infection rate compared to population
SELECT 
    continent, 
    SUM(population) AS total_population,
    SUM(total_cases) AS total_cases,
    (SUM(total_cases) / SUM(population)) * 100 AS infection_rate_percentage
FROM
	PortfolioProject..CovidDeaths
WHERE
	continent IS NOT NULL
GROUP BY
	continent
ORDER BY
	infection_rate_percentage DESC;


--Continents With Highest Death Count
select 
	continent,
	MAX(total_deaths) AS TotalDeathCount
from
	PortfolioProject..CovidDeaths
--where location = 'Egypt'
where
	continent IS NOT NULL
group by
	continent
order by
	TotalDeathCount DESC;

--Global Numbers

SELECT
    date,
    SUM(new_cases) AS total_new_cases,
    SUM(new_deaths) AS total_new_deaths,
    CASE
        WHEN SUM(new_cases) = 0 THEN NULL -- Avoid division by zero
        ELSE (SUM(new_deaths) / NULLIF(SUM(new_cases), 0)) * 100
    END AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL
GROUP BY
    date
ORDER BY
    1,2;

-- Case Fatality Rate Over Time by Country
SELECT 
    location,
    date,
    SUM(total_cases) AS TotalCases,
    SUM(total_deaths) AS TotalDeaths,
    (SUM(total_deaths) / NULLIF(SUM(total_cases), 0)) * 100 AS CFR
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL
GROUP BY 
    location, date
ORDER BY 
    location, date;

-- Analysis of Stringency Measures vs. Case Reduction
SELECT 
    d.location,
    d.date,
    s.stringency_index,
    d.new_cases
FROM 
    PortfolioProject..CovidDeaths d
JOIN 
    PortfolioProject..CovidVaccinations s ON d.location = s.location AND d.date = s.date
WHERE 
    d.continent IS NOT NULL
ORDER BY 
    d.location, d.date;

-- Highest Daily Increase in Cases and Deaths by Country
SELECT TOP 10
    location,
    date,
    new_cases,
    new_deaths
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL
ORDER BY 
    new_cases DESC, new_deaths DESC;




--Death Percentage Around The World
SELECT
    SUM(new_cases) AS total_new_cases,
    SUM(new_deaths) AS total_new_deaths,
    CASE
        WHEN SUM(new_cases) = 0 THEN NULL -- Avoid division by zero
        ELSE (SUM(new_deaths) / NULLIF(SUM(new_cases), 0)) * 100
    END AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL
ORDER BY
    1,2;

--Analyzing Total Population VS Vaccinations

SELECT
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(v.new_vaccinations) OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
	--RollingPeopleVaccinated/d.population
FROM
	PortfolioProject..CovidDeaths d
JOIN
	PortfolioProject..CovidVaccinations v
ON
	d.location = v.location
AND
	d.date = v.date
WHERE 
    d.continent IS NOT NULL
ORDER BY 
	2,3;

-- Weekly Changes in Cases and Deaths
SELECT 
    location,
    YEAR(date) AS Year,
    DATEPART(week, date) AS Week,
    SUM(new_cases) AS TotalNewCases,
    SUM(new_deaths) AS TotalNewDeaths,
    LAG(SUM(new_cases), 1) OVER (PARTITION BY location ORDER BY YEAR(date), DATEPART(week, date)) AS PreviousWeekCases,
    LAG(SUM(new_deaths), 1) OVER (PARTITION BY location ORDER BY YEAR(date), DATEPART(week, date)) AS PreviousWeekDeaths,
    (SUM(new_cases) - LAG(SUM(new_cases), 1) OVER (PARTITION BY location ORDER BY YEAR(date), DATEPART(week, date))) AS ChangeInCases,
    (SUM(new_deaths) - LAG(SUM(new_deaths), 1) OVER (PARTITION BY location ORDER BY YEAR(date), DATEPART(week, date))) AS ChangeInDeaths
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL
GROUP BY 
    location, YEAR(date), DATEPART(week, date)
ORDER BY 
    location, Year, Week;


-- Correlation of Vaccination and Case Reduction
WITH VaccinationData AS (
    SELECT 
        location,
        date,
        SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY date) AS CumulativeVaccinations
    FROM 
        PortfolioProject..CovidVaccinations
)
SELECT 
    d.location,
    d.date,
    d.new_cases,
    v.CumulativeVaccinations
FROM 
    PortfolioProject..CovidDeaths d
JOIN 
    VaccinationData v ON d.location = v.location AND d.date = v.date
WHERE 
    d.continent IS NOT NULL
ORDER BY 
    d.location, d.date;

--Use CTE
With PopvsVac (continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(v.new_vaccinations) OVER (Partition by d.location Order by d.location, d.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths d
Join PortfolioProject..CovidVaccinations v
	On d.location = v.location
	and d.date = v.date
where d.continent is not null 
--order by 2,3
)

SELECT *, (RollingPeopleVaccinated/population)*100 AS VaccinatedPercentage
FROM PopvsVac;

--Temp Table

DROP  TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(v.new_vaccinations) OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
	--RollingPeopleVaccinated/d.population
FROM
	PortfolioProject..CovidDeaths d
JOIN
	PortfolioProject..CovidVaccinations v
ON
	d.location = v.location
AND
	d.date = v.date
WHERE 
    d.continent IS NOT NULL
--ORDER BY 2,3;

SELECT *, (RollingPeopleVaccinated/population)*100 AS VaccinatedPercentage
FROM #PercentPopulationVaccinated;

--creating views to store data for visualization
CREATE VIEW PercentPopulationVaccinated AS
SELECT
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(v.new_vaccinations) OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
	--RollingPeopleVaccinated/d.population
FROM
	PortfolioProject..CovidDeaths d
JOIN
	PortfolioProject..CovidVaccinations v
ON
	d.location = v.location
AND
	d.date = v.date
WHERE 
    d.continent IS NOT NULL
--ORDER BY 2,3;

SELECT *
FROM PercentPopulationVaccinated