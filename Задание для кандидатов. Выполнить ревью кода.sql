-- В начале скрипта отсутствует комментарий
create procedure syn.usp_ImportFileCustomerSeasonal
	@ID_Record int
as
set nocount on
begin
	-- Переменные должны задаваться в одном обьявлении
	declare @RowCount int = (select count(*) from syn.SA_CustomerSeasonal)
	-- Указана длина поля max
	declare @ErrorMessage varchar(max)

-- У комментария должен быть такой же отступ, как и у блока, к которому он написан
-- Проверка на корректность загрузки
	-- В конструкции if весь блок на 1 отступ
	if not exists (
	select 1
	from syn.ImportFile as f
	where f.ID = @ID_Record
		-- Неявное преобразование int в bit
		and f.FlagLoaded = cast(1 as bit)
	)
		-- begin и end должны быть на том же отступе, что и if
		begin
			set @ErrorMessage = 'Ошибка при загрузке файла, проверьте корректность данных'

			raiserror(@ErrorMessage, 3, 1)
			-- Нет пустой строки перед return
			return
		end

	-- Операторы должны быть в нижнем регистре
	CREATE TABLE #ProcessedRows (
		-- В создаваемой таблице должны быть поля MDT_DateCreate, MDT_ID_PrincipalCreatedBy
		ActionType varchar(255),
		ID int
	)

	-- Отсутствует пробел перед текстом комментария
	--Чтение из слоя временных данных
	select
		cc.ID as ID_dbo_Customer
		,cst.ID as ID_CustomerSystemType
		,s.ID as ID_Season
		,cast(cs.DateBegin as date) as DateBegin
		,cast(cs.DateEnd as date) as DateEnd
		,cd.ID as ID_dbo_CustomerDistributor
		,cast(isnull(cs.FlagActive, 0) as bit) as FlagActive
	into #CustomerSeasonal
	-- Отсутствует ключевое слово as
	from syn.SA_CustomerSeasonal cs
		-- Все join должны указываться явно 
		join dbo.Customer as cc on cc.UID_DS = cs.UID_DS_Customer
			and cc.ID_mapping_DataSource = 1
		join dbo.Season as s on s.Name = cs.Season
		join dbo.Customer as cd on cd.UID_DS = cs.UID_DS_CustomerDistributor
			and cd.ID_mapping_DataSource = 1
		-- Сперва нужно указать поле присоединяемой таблицы
		join syn.CustomerSystemType as cst on cs.CustomerSystemType = cst.Name
	where try_cast(cs.DateBegin as date) is not null
		and try_cast(cs.DateEnd as date) is not null
		and try_cast(isnull(cs.FlagActive, 0) as bit) is not null

	-- 2 однострочных комментария вместо многострочного
	-- Определяем некорректные записи
	-- Добавляем причину, по которой запись считается некорректной
	select
		cs.*
		,case
			-- then должен быть на отдельной строке и на 1 отступ от when
			when cc.ID is null then 'UID клиента отсутствует в справочнике "Клиент"'
			when cd.ID is null then 'UID дистрибьютора отсутствует в справочнике "Клиент"'
			when s.ID is null then 'Сезон отсутствует в справочнике "Сезон"'
			when cst.ID is null then 'Тип клиента в справочнике "Тип клиента"'
			when try_cast(cs.DateBegin as date) is null then 'Невозможно определить Дату начала'
			-- Дату окончания, вероятно
			when try_cast(cs.DateEnd as date) is null then 'Невозможно определить Дату начала'
			when try_cast(isnull(cs.FlagActive, 0) as bit) is null then 'Невозможно определить Активность'
		end as Reason
	into #BadInsertedRows
	from syn.SA_CustomerSeasonal as cs
	left join dbo.Customer as cc on cc.UID_DS = cs.UID_DS_Customer
		and cc.ID_mapping_DataSource = 1
	-- and должен быть на отдельной строке и на 1 отступ от join
	left join dbo.Customer as cd on cd.UID_DS = cs.UID_DS_CustomerDistributor and cd.ID_mapping_DataSource = 1
	left join dbo.Season as s on s.Name = cs.Season
	left join syn.CustomerSystemType as cst on cst.Name = cs.CustomerSystemType
	where cc.ID is null
		or cd.ID is null
		or s.ID is null
		or cst.ID is null
		or try_cast(cs.DateBegin as date) is null
		or try_cast(cs.DateEnd as date) is null
		or try_cast(isnull(cs.FlagActive, 0) as bit) is null
-- Лишняя пустая строка внутри логического блока
		
end
