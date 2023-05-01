# Портфолио: аналитик данных

## Обо мне 

Привет! Меня зовут Максим Королев, я начинающий аналитик данных. 
Занимаюсь изучением и практикой в области аналитики данных.
Практиковался в веб-программировании, мобильных приложениях и телеграм ботах, а также разных прикладных парсеров.
Есть высшее техническое образоание, напрямую связанное с IT.
В этом репозитории вы можете найти некоторые из моих проектов, выполненных во время обучения и практики.
<br>

## Навыки и технологии
- Инструменты анализа данных: ``SQL``, ``Excel``: 
- Языки программирования и библиотеки: ``Python``, ``Pandas``, ``math`` 
- Системы управления базами данных: ``MySQL``, ``PostgreSQL``, ``Metabase``
- Средства визуализации данных: ``Matplotlib``, ``seaborn``


## Проекты

### Проект 1: Калькулятор юнит-экономики онлайн-кинотеатра

<p>Что нужно было сделать:<p>
<ol>
  <li>Определить, что является юнитом в нашей экономике.</li>
  <li>Посчитать юнит-экономику продукта и предложить сценарий по настройке параметров для выхода на 25%-ную маржинальность.</li>
  <li>Выбрать оптимальный вариант расчета Retention.</li>
  <li>Собрать визуализации основных бизнес-показателей.</li>
  <li>Исследовать данные о пользователях и их поведении.</li>
</ol>

<p>Как задача была решена:
Из исходных данных выясняется, что юнитом является подписка, для калькулятора нам требуется определить несколько параметров:

#### Retention

Известны даты подписок каждого подписчика, из них мы должны выяснить даты первых подписок, это нужно для определения новых и старых подписчиков, когда эти показатели будут найдены, то новых к старым подписчикам покажет нам сколько мы смогли удержать, затем средним геометрическим мы находим средний Retantion и первый показатель для юнит-калькулятора известен.

#### Lifetime

Нужно выяснить сколько в среднем находится наш подписчик на платформе, сделаем это с помощью Retention.

#### CAC

Нам уже известно сколько новых подписчиков приходит к нам на платформу каждый месяц, а также нам известны затраты на маркетинг, найдём общий показатель трат на каждого нового подписчика и получим средний CAC, который также будет добавлен в калькулятор.

#### CAC на 1 юнит

Для этого нам нужно найти отношение нашего среднего CAC к Lifetime

#### Базовая/Фактическая цена подписки

Базовая цена подписки нам известна, а фактическую цену мы узнаём из отношения выручки к подписчикам за весь период, также мы узнаем сколько составляет наш объем скидок за весь период.

#### LTR

Теперь можно найти один из ключевых показателей. Сколько денег нам приносит юнит за свою жизнь. Это мы найдём произведением фактической цены подписки на время жизни.

#### Fixed Costs на юнит

Нам известны только сумма постоянных трат, мы можем найти среднее значение трат за весь период отношением трат к количеству подписок.

#### Маржинальность

Финальный ключевой показатель. Сумма наших трат на цену фактической подписки.
<p>


> <a href="https://github.com/L-413N/portfallio/tree/main/UnitCalc">Ссылка на проект</a>

<p>Итоги:<p>
<ol>
  <li>Все вычисленные параметры были внесены в калькулятор. Манипулируя ими мы можем пересмотреть наши траты или/и стоимость услуг для повышения прибыли</li>
  <li>Система подписок показала свою невыгодность на заданном промежутке времени</li>
</ol>
<br> 

### Проект 2: Модель изменения балансов студентов

<p>Что нужно было сделать:<p>
<ol>
  <li>Собрать таблицу с изменением балансов студентов</li>
  <li>Проанализировать как изменялись балансы</li>
</ol>

<p>Алгоритм решения:

#### Подготовка CTE запросов

Для начала определяем первые даты оплат для каждого студента посредством запроса:

<code>
    SELECT
        user_id,
        MIN(transaction_datetime::date)::date AS first_payment_date
    FROM skyeng_db.payments AS s
    WHERE status_name = 'success'
    GROUP BY s.user_id
</code>

Этот запрос будет первым CTE для определения балансов.

Нам нужно взять даты только за 2016 год:

<code>
    SELECT DISTINCT(class_start_datetime::date) AS dt
    FROM skyeng_db.classes
    WHERE DATE_TRUNC('year', class_start_datetime::date) = '2016-01-01'
</code>

Из всех известных транзакций нужно оставить только успешные:

<code>
    SELECT 
        user_id, 
        transaction_datetime::date AS payment_date,
        SUM(classes) AS transaction_balance_change
    FROM skyeng_db.payments
    WHERE status_name = 'success'
    GROUP BY user_id, payment_date
</code>

Каждый опрос будет отдельным CTE, теперь нужно определить даты для каждого студента после их первой оплаты и то, как изменялся их баланс за каждый день уроков.
Для начала определим даты после первой транзакции для каждого ученика:

<code>
    SELECT 
        user_id, 
        dt 
    FROM all_dates AS ad
    LEFT JOIN first_payments AS fp
        ON ad.dt >= fp.first_payment_date
</code>
Затем количество уроков за каждый день для каждого ученика (количество уроков мы умножаем на -1, т.к это показатель того, сколько уроков в этот день было списано уроков):
<code>
    SELECT
        user_id,
        class_start_datetime::date AS class_date,
        COUNT(*) * -1 AS classes
    FROM skyeng_db.classes AS c
    WHERE
        class_type = 'regular'
        AND class_status IN ('success', 'failed_by_student')
    GROUP BY user_id, class_date
</code>

#### Определеяем балансы

Для начала нужно найти баланс студентов, который сформирован только транзакциями.
Этот баланс будет накопительным, чтобы мы могли посмотреть более гладко, что происходио с балансами учеников:

<code>
    SELECT 
        adbu.user_id,
        adbu.dt,
        transaction_balance_change,
        SUM(pbd.transaction_balance_change) OVER (PARTITION BY adbu.user_id ORDER BY adbu.dt ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS transaction_balance_change_cs 
    FROM all_dates_by_user AS adbu
    LEFT JOIN payments_by_dates AS pbd
        ON adbu.user_id = pbd.user_id
        AND adbu.dt = pbd.payment_date
</code>

Аналогичный запрос будет на накопительную таблицу с количеством уроков студентов:

<code>
    SELECT
        adbu.user_id,
        dt,
        classes,
        SUM(classes) OVER (PARTITION BY adbu.user_id ORDER BY dt ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS classes_cs
    FROM all_dates_by_user AS adbu
    LEFT JOIN classes_by_dates AS cbd
        ON cbd.user_id = adbu.user_id
        AND cbd.class_date = adbu.dt
</code>

Затем создадим таблицу, объединяющую информацию о балансах студентов по транзакциям и урокам:

<code>
        pbdc.user_id,
        pbdc.dt,
        pbdc.transaction_balance_change,
        pbdc.transaction_balance_change_cs,
        cbddc.classes,
        cbddc.classes_cs,
        pbdc.transaction_balance_change_cs + cbddc.classes_cs AS balance
    FROM payments_by_dates_cumsum AS pbdc
    JOIN classes_by_dates_dates_cumsum AS cbddc
        ON pbdc.user_id = cbddc.user_id
        AND pbdc.dt = cbddc.dt
</code>

Теперь, на основе собранной таблицы создадим общую аналитическую с суммами всех показателей по датам:

<code>
SELECT
    dt,
    SUM(transaction_balance_change) AS transaction_balance_change_sum,
    SUM(transaction_balance_change_cs) AS transaction_balance_change_cs_sum,
    SUM(classes) AS classes_sum,
    SUM(classes_cs) AS classes_cs_sum,
    SUM(balance) AS balance_sum
FROM balances
GROUP BY dt
</code>

<p>

> <a href="https://github.com/L-413N/portfallio/tree/main/student_balances">Ссылка на проект</a>
 
Итоги:
<ol>
  <li>Сформирован скрипт для детального анализа изменения балансов</li>
  <li>Анализ показал нормальную динамику балансов по всем показателям</li>
</ol>
<br> 

## Контактная информация
- Email: folenrey@email.com
- TG: @LordFolen
