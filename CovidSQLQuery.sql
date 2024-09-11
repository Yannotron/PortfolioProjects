select *
from ['coviddeaths']
order by 3,4

--select *
--from ['covidvaccinations']
--order by 3,4


select location, date, total_cases, new_cases, total_deaths, population
from ['coviddeaths']

-- looking at total cases vs total deaths per country--

select 
	location, 
	max(total_cases) cases,
	max(total_deaths) deaths,
	format((100*max(total_deaths)/max(total_cases)) , 'N2')+ '%' as ratio
from ['coviddeaths']
where total_cases>0 and continent is not null
group by location
order by 3 desc

-- looking at total cases per population per day in France

select 
	location, 
	date,
	format(population, 'n0') pop,
	format(total_cases, 'n0') cases,
	format(100*(total_cases/population), 'n2') + '%' as ratio
from ['coviddeaths']
where location like 'France'

countries 

-- looking at countris with highest daily infection rate vs population

select 
	location, 
	population, 
	max(total_cases) 'Highest infection',
	concat(cast((max(total_cases/population*100)) as decimal (10,2)),'%') 'Percentage pop infected'
from ['coviddeaths']
group by location, population
order by max(total_cases/population*100) desc

-- showing countries with highest deaths count per population

select 
	location, 
	cast(max(total_deaths) as decimal (10,0)) 'Total deaths count'
from ['coviddeaths']
where continent is not null
group by location
order by 2 desc

-- showing continent with highest deaths counts

select 
	location, 
	cast(max(total_deaths) as decimal (10,0)) 'Total deaths count'
from ['coviddeaths']
where continent is null
group by location
order by 2 desc

-- Global numbers

select date, sum(new_cases) cases, sum(new_deaths) deaths, sum(new_deaths)/sum(new_cases)*100 as ratio
from ['coviddeaths']
where new_cases >0
group by date
order by 1


-- looking at total population vs vaccinations

select 
	dea.continent, 
	dea.location, 
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(cast(new_vaccinations as bigint)) over(partition by dea.location order by dea.location, dea.date) as 'rolling people vaccinated'
from ['coviddeaths'] dea
join ['covidvaccinations'] vac
	on dea.location = vac.location and 
	dea.date = vac.date
where dea.continent is not null
order by 2,3

-- use CTE

with popsvac (continent, location, date, population, new_vaccinations, rollingPeopleVaccinated) as
 ( select
	dea.continent, 
	dea.location, 
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(cast(new_vaccinations as bigint)) over(partition by dea.location order by dea.location, dea.date) as 'rollingPeopleVaccinated'
from ['coviddeaths'] dea
join ['covidvaccinations'] vac
	on dea.location = vac.location and 
	dea.date = vac.date
where dea.continent is not null
-- order by 2,3
)
select *,
		rollingPeopleVaccinated/population * 100
from popsvac

-- with temp file


drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated (
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingPeopleVaccinated numeric)


insert into #PercentPopulationVaccinated
select 
	dea.continent, 
	dea.location, 
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(cast(new_vaccinations as bigint)) over(partition by dea.location order by dea.location, dea.date) as 'rolling people vaccinated'
from ['coviddeaths'] dea
join ['covidvaccinations'] vac
	on dea.location = vac.location and 
	dea.date = vac.date
where dea.continent is not null
order by 2,3

select * , rollingPeopleVaccinated/population * 100
from #PercentPopulationVaccinated
order by location

-- creating views to store data for later visualisations

create view PercentPopulationVaccinated as
select 
	dea.continent, 
	dea.location, 
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(cast(new_vaccinations as bigint)) over(partition by dea.location order by dea.location, dea.date) as 'rolling people vaccinated'
from ['coviddeaths'] dea
join ['covidvaccinations'] vac
	on dea.location = vac.location and 
	dea.date = vac.date
where dea.continent is not null