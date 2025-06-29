--
-- PostgreSQL database dump
--

-- Dumped from database version 17.0
-- Dumped by pg_dump version 17.0

-- Started on 2025-06-16 14:24:15

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 252 (class 1255 OID 41277)
-- Name: add_request(integer, integer, date, numeric, date, smallint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_request(p_id_supplier integer, p_id_manager integer, p_data_registration date, p_cost_request numeric, p_data_action date, p_action_type smallint) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  error_message TEXT;
  new_status SMALLINT;
BEGIN
  -- Проверяем входные данные
  IF p_cost_request IS NULL OR p_cost_request <= 0 THEN
    error_message := 'Стоимость заявки должна быть положительной.';
    RAISE EXCEPTION '%', error_message;
  END IF;

  IF p_data_registration IS NULL THEN
    error_message := 'Дата регистрации заявки должна быть указана.';
    RAISE EXCEPTION '%', error_message;
  END IF;

  -- Определяем статус заявки
  IF p_data_action IS NOT NULL THEN
    new_status := 3; -- Статус "Выполнена"
  ELSE
    new_status := 0; -- Статус "Новая" (предположим, это начальный статус)
  END IF;

  -- Вставляем новую заявку в таблицу
  BEGIN
    INSERT INTO ordering (
      id_supplier,
      id_manager,
      data_registration,
      cost_request,
      data_action,
      action_type,
      status_request
    )
    VALUES (
      p_id_supplier,
      p_id_manager,
      p_data_registration,
      p_cost_request,
      p_data_action,
      p_action_type,
      new_status
    );

    -- Сообщение об успешной вставке
    RAISE NOTICE 'Заявка успешно добавлена. Статус: %', new_status;

  EXCEPTION
    WHEN OTHERS THEN
      -- Откатываем транзакцию в случае ошибки
      ROLLBACK;
      RAISE NOTICE 'Ошибка при добавлении заявки: %', SQLERRM;
      RAISE NOTICE 'Операция откатана.';
      RETURN;
  END;

  -- Фиксируем транзакцию
  COMMIT;

END;
$$;


ALTER FUNCTION public.add_request(p_id_supplier integer, p_id_manager integer, p_data_registration date, p_cost_request numeric, p_data_action date, p_action_type smallint) OWNER TO postgres;

--
-- TOC entry 253 (class 1255 OID 41278)
-- Name: add_request1(integer, integer, date, numeric, date, smallint); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.add_request1(IN p_id_supplier integer, IN p_id_manager integer, IN p_data_registration date, IN p_cost_request numeric, IN p_data_action date, IN p_action_type smallint)
    LANGUAGE plpgsql
    AS $$
DECLARE
  error_message TEXT;
  new_status SMALLINT;
  existing_request INTEGER;
BEGIN
  -- Проверяем входные данные
  IF p_cost_request IS NULL OR p_cost_request <= 0 THEN
    error_message := 'Стоимость заявки должна быть положительной.';
    RAISE EXCEPTION '%', error_message;
  END IF;

  IF p_data_registration IS NULL THEN
    error_message := 'Дата регистрации заявки должна быть указана.';
    RAISE EXCEPTION '%', error_message;
  END IF;

  -- Проверка существования id_supplier
  IF NOT EXISTS (SELECT 1 FROM supplier WHERE id_supplier = p_id_supplier) THEN
    RAISE EXCEPTION 'Поставщик с id % не существует.', p_id_supplier;
  END IF;

  -- Проверка существования id_manager
  IF NOT EXISTS (SELECT 1 FROM manager WHERE id_manager = p_id_manager) THEN
    RAISE EXCEPTION 'Менеджер с id % не существует.', p_id_manager;
  END IF;

  -- Проверка на существование заявки с таким же идентификатором
  SELECT COUNT(*) INTO existing_request
  FROM request
  WHERE cost_request = p_cost_request
  AND id_supplier = p_id_supplier
  AND data_registration = p_data_registration;

  IF existing_request > 0 THEN
    RAISE EXCEPTION 'Заявка с таким идентификатором уже существует.';
  END IF;

  -- Определяем статус заявки
  IF p_data_action IS NOT NULL THEN
    new_status := 3; -- Статус "Выполнена"
  ELSE
    new_status := 1; -- Статус "Новая"
  END IF;

  -- Вставляем новую заявку в таблицу
  BEGIN
    INSERT INTO request (
      id_supplier,
      id_manager,
      data_registration,
      cost_request,
      data_action,
      action_type,
      status_request
    )
    VALUES (
      p_id_supplier,
      p_id_manager,
      p_data_registration,  -- Используем текущую дату, если не указана дата
      p_cost_request,
      p_data_action,
      p_action_type,
      new_status
    );

    -- Сообщение об успешной вставке
    RAISE NOTICE 'Заявка успешно добавлена. Статус: %', new_status;

  EXCEPTION
    WHEN OTHERS THEN
      -- Откатываем транзакцию в случае ошибки
      ROLLBACK;
      RAISE NOTICE 'Ошибка при добавлении заявки: %', SQLERRM;
      RAISE NOTICE 'Операция откатана.';
      RETURN;
  END;

  -- Фиксируем транзакцию
  COMMIT;

END;
$$;


ALTER PROCEDURE public.add_request1(IN p_id_supplier integer, IN p_id_manager integer, IN p_data_registration date, IN p_cost_request numeric, IN p_data_action date, IN p_action_type smallint) OWNER TO postgres;

--
-- TOC entry 251 (class 1255 OID 41274)
-- Name: addrequestandorder(integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.addrequestandorder(p_id_request integer, p_id_manager integer, p_id_supplier integer, p_id_client integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- 1. Добавляем новую заявку
    INSERT INTO request (id_request, data_registration, status_request, cost_request, data_action, action_type, id_supplier, id_manager)
    VALUES (p_id_request, NOW(), 0, 0.00, NULL, 1, p_id_supplier, p_id_manager);

    -- 2. Добавляем новый заказ
    INSERT INTO ordering (id_ordering, date_ordering, datepay_ordering, status_ordering, id_manager, id_client)
    VALUES (p_id_request, NOW(), NOW() + INTERVAL '7 days', 0, p_id_manager, p_id_client);

    -- 3. Вывод добавленной строки из таблицы request
    RAISE NOTICE 'Request: %', (SELECT * FROM request WHERE id_request = p_id_request);

    -- 4. Вывод добавленной строки из таблицы ordering
    RAISE NOTICE 'Ordering: %', (SELECT * FROM ordering WHERE id_ordering = p_id_request);
END;
$$;


ALTER FUNCTION public.addrequestandorder(p_id_request integer, p_id_manager integer, p_id_supplier integer, p_id_client integer) OWNER TO postgres;

--
-- TOC entry 235 (class 1255 OID 41275)
-- Name: cancel_unpaid_orders(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cancel_unpaid_orders() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Проверяем, если заказ был создан более недели назад и не оплачен
  IF NEW.datepay_ordering IS NULL AND NEW.date_ordering <= CURRENT_DATE - INTERVAL '7 days' THEN
    -- Обновляем статус на 'Отменен'
    NEW.status_ordering := '7';
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.cancel_unpaid_orders() OWNER TO postgres;

--
-- TOC entry 236 (class 1255 OID 41267)
-- Name: handle_request_activity(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.handle_request_activity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Добавление новой строки
        NEW.Action_Type := 3;  -- Тип активности "Добавлено"
        NEW.Data_Action := NOW();  -- Текущая дата/время

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        -- Обновление существующей строки
        NEW.Action_Type := 2;  -- Тип активности "Изменено"
        NEW.Data_Action := NOW();  -- Текущая дата/время

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        -- Логирование при удалении строки (сохраняем старую строку)
        INSERT INTO Log_DeletedRequests (ID_Request, Status_Request, Action_Type, Data_Action, Deleted_At)
        VALUES (OLD.ID_Request, OLD.Status_Request, OLD.Action_Type, OLD.Data_Action, NOW());

        RETURN OLD;
    END IF;

    RETURN NULL; -- Защита от неопределенного поведения
END;
$$;


ALTER FUNCTION public.handle_request_activity() OWNER TO postgres;

--
-- TOC entry 248 (class 1255 OID 41271)
-- Name: process_request_transaction(integer, smallint, numeric, integer, integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.process_request_transaction(IN p_request_id integer, IN p_status_request smallint, IN p_cost_request numeric, IN p_identifier_1 integer, IN p_order_id integer, IN p_user_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    order_details RECORD; 
BEGIN
    BEGIN

        -- 1. Добавление новой заявки в таблицу request
        INSERT INTO request (ID_Request, Data_Registration, Status_Request, Cost_Request, Identifier_1)
        VALUES (p_request_id, NOW(), p_status_request, p_cost_request, p_identifier_1);

        -- 2. Обновление статуса связанного заказа
        UPDATE "order"
        SET Status_Ordering = 1  -- "В процессе"
        WHERE ID_Ordering = p_order_id;

        -- 3. Логирование действий в таблицу log_request_actions
        INSERT INTO log_request_actions (ID_Request, User_ID, Action_Type, Action_Timestamp)
        VALUES (p_request_id, p_user_id, 'CREATE', NOW());

        -- 4. Выборка обновлённых данных о заказе для возврата
        SELECT *
        INTO order_details
        FROM "order"
        WHERE ID_Ordering = p_order_id;

        RAISE NOTICE 'Order Details: ID: %, Status: %, Last Updated: %',
            order_details.ID_Ordering, order_details.Status_Ordering, order_details.Last_Updated;

    EXCEPTION WHEN OTHERS THEN
        -- Откат изменений при возникновении ошибки
        RAISE NOTICE 'Transaction failed: %', SQLERRM;
        ROLLBACK;
        RETURN;
    END;

    COMMIT;

END;
$$;


ALTER PROCEDURE public.process_request_transaction(IN p_request_id integer, IN p_status_request smallint, IN p_cost_request numeric, IN p_identifier_1 integer, IN p_order_id integer, IN p_user_id integer) OWNER TO postgres;

--
-- TOC entry 250 (class 1255 OID 41273)
-- Name: process_request_with_triggers(integer, smallint, numeric, integer, integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.process_request_with_triggers(IN p_request_id integer, IN p_status_request smallint, IN p_cost_request numeric, IN p_supplier_id integer, IN p_manager_id integer, IN p_user_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    request_info RECORD;       -- Переменная для хранения информации о заявке
BEGIN
    -- Начало транзакции
    BEGIN
        -- 1. Добавление новой заявки в таблицу request
        INSERT INTO request (id_request, id_supplier, id_manager, data_registration, status_request, cost_request)
        VALUES (p_request_id, p_supplier_id, p_manager_id, NOW(), p_status_request, p_cost_request);

        -- Триггер автоматически активируется:
        -- Поля action_type и data_action будут обновлены триггером `trg_handle_request_insert`.

        -- 2. Обновление статуса заявки
        UPDATE request
        SET status_request = CASE
            WHEN p_status_request = 1 THEN 2  -- Если заявка подтверждена, меняем статус на "В процессе"
            WHEN p_status_request = 0 THEN 1  -- Если заявка новая, статус остается "Ожидание"
            ELSE status_request
        END
        WHERE id_request = p_request_id;

        -- 3. Логирование действий в таблицу log_request_actions
        INSERT INTO log_request_actions (id_request, user_id, action_type, action_timestamp)
        VALUES (p_request_id, p_user_id, 'CREATE', NOW());

        -- 4. Выборка информации о заявке для подтверждения транзакции
        SELECT *
        INTO request_info
        FROM request
        WHERE id_request = p_request_id;

        -- Вывод информации для проверки
        RAISE NOTICE 'Request Details: ID: %, Status: %, Cost: %, Action_Type: %, Data_Action: %',
            request_info.id_request, request_info.status_request, request_info.cost_request,
            request_info.action_type, request_info.data_action;

    EXCEPTION WHEN OTHERS THEN
        -- Откат изменений при возникновении ошибки
        RAISE NOTICE 'Transaction failed: %', SQLERRM;
        ROLLBACK;
        RETURN;
    END;

    -- Завершение транзакции
    COMMIT;
END;
$$;


ALTER PROCEDURE public.process_request_with_triggers(IN p_request_id integer, IN p_status_request smallint, IN p_cost_request numeric, IN p_supplier_id integer, IN p_manager_id integer, IN p_user_id integer) OWNER TO postgres;

--
-- TOC entry 249 (class 1255 OID 41272)
-- Name: process_request_with_triggers(integer, integer, numeric, integer, integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.process_request_with_triggers(IN p_request_id integer, IN p_status_request integer, IN p_cost_request numeric, IN p_id_request integer, IN p_order_id integer, IN p_user_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    request_info RECORD;       -- Переменная для хранения информации о заявке
    order_info RECORD;         -- Переменная для хранения информации о заказе
BEGIN
    -- Начало транзакции
    BEGIN
        -- 1. Добавление новой заявки в таблицу request
        INSERT INTO request (ID_Request, Data_Registration, Status_Request, Cost_Request, identifier)
        VALUES (p_request_id, NOW(), p_status_request, p_cost_request, p_identifier);

        -- Триггер автоматически активируется:
        -- Поля Action_Type и Data_Action будут обновлены триггером `trg_handle_request_insert`.

        -- 2. Обновление статуса связанного заказа в таблице order
        UPDATE "order"
        SET Status_Ordering = CASE
            WHEN p_status_request = 1 THEN 2  -- Если заявка подтверждена, статус заказа "В процессе"
            WHEN p_status_request = 0 THEN 1  -- Если заявка новая, статус заказа "Ожидание"
            ELSE Status_Ordering
        END
        WHERE ID_Ordering = p_order_id;

        -- 3. Логирование действий в таблицу log_request_actions
        INSERT INTO log_request_actions (ID_Request, User_ID, Action_Type, Action_Timestamp)
        VALUES (p_request_id, p_user_id, 'CREATE', NOW());

        -- 4. Выборка информации о заявке для подтверждения транзакции
        SELECT *
        INTO request_info
        FROM request
        WHERE ID_Request = p_request_id;

        -- 5. Выборка информации о заказе для подтверждения транзакции
        SELECT *
        INTO order_info
        FROM "order"
        WHERE ID_Ordering = p_order_id;

        -- Вывод информации для проверки
        RAISE NOTICE 'Request Details: ID: %, Status: %, Cost: %, Action_Type: %, Data_Action: %',
            request_info.ID_Request, request_info.Status_Request, request_info.Cost_Request,
            request_info.Action_Type, request_info.Data_Action;

        RAISE NOTICE 'Order Details: ID: %, Status: %, Last Updated: %',
            order_info.ID_Ordering, order_info.Status_Ordering, order_info.Last_Updated;

    EXCEPTION WHEN OTHERS THEN
        -- Откат изменений при возникновении ошибки
        RAISE NOTICE 'Transaction failed: %', SQLERRM;
        ROLLBACK;
        RETURN;
    END;

    -- Завершение транзакции
    COMMIT;
END;
$$;


ALTER PROCEDURE public.process_request_with_triggers(IN p_request_id integer, IN p_status_request integer, IN p_cost_request numeric, IN p_id_request integer, IN p_order_id integer, IN p_user_id integer) OWNER TO postgres;

--
-- TOC entry 234 (class 1255 OID 41265)
-- Name: update_activity_type_and_date(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_activity_type_and_date() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Обновляем тип активности и дату активности
    NEW.Action_Type := 2;  -- Устанавливаем новый тип активности (например, "2" - действие выполнено)
    NEW.Data_Action := NOW();  -- Обновляем дату активности на текущую

    RETURN NEW;  -- Возвращаем обновленную строку
END;
$$;


ALTER FUNCTION public.update_activity_type_and_date() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 218 (class 1259 OID 33074)
-- Name: client; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client (
    id_client integer NOT NULL,
    numberphone_client character varying(20) NOT NULL,
    snp_client character varying(255) NOT NULL,
    passport_client character varying(50) NOT NULL,
    login_client character varying(100),
    password_client character varying(256)
);


ALTER TABLE public.client OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 33073)
-- Name: client_id_client_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.client_id_client_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.client_id_client_seq OWNER TO postgres;

--
-- TOC entry 4973 (class 0 OID 0)
-- Dependencies: 217
-- Name: client_id_client_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.client_id_client_seq OWNED BY public.client.id_client;


--
-- TOC entry 219 (class 1259 OID 33081)
-- Name: configuration; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.configuration (
    vin character varying(17) NOT NULL,
    id_model integer NOT NULL,
    name_config character varying(255) NOT NULL
);


ALTER TABLE public.configuration OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 33089)
-- Name: manager; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.manager (
    id_manager integer NOT NULL,
    snp_manager character varying(255) NOT NULL,
    start_date date,
    login_manager character varying(100),
    password_manager character varying(256),
    role character varying(128)
);


ALTER TABLE public.manager OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 33088)
-- Name: manager_id_manager_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.manager_id_manager_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.manager_id_manager_seq OWNER TO postgres;

--
-- TOC entry 4974 (class 0 OID 0)
-- Dependencies: 220
-- Name: manager_id_manager_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.manager_id_manager_seq OWNED BY public.manager.id_manager;


--
-- TOC entry 223 (class 1259 OID 33097)
-- Name: model; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.model (
    id_model integer NOT NULL,
    name_model character varying(255) NOT NULL,
    yearstart_model character varying(4) NOT NULL,
    yearend_model character varying(4),
    bodyno_model character varying(12) NOT NULL
);


ALTER TABLE public.model OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 33096)
-- Name: model_id_model_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.model_id_model_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.model_id_model_seq OWNER TO postgres;

--
-- TOC entry 4975 (class 0 OID 0)
-- Dependencies: 222
-- Name: model_id_model_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.model_id_model_seq OWNED BY public.model.id_model;


--
-- TOC entry 224 (class 1259 OID 33104)
-- Name: order_parts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_parts (
    id_ordering integer NOT NULL,
    id_part integer NOT NULL,
    id_request integer,
    quantity_parts integer NOT NULL
);


ALTER TABLE public.order_parts OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 33114)
-- Name: ordering; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ordering (
    id_ordering integer NOT NULL,
    id_manager integer,
    id_client integer NOT NULL,
    date_ordering date NOT NULL,
    datepay_ordering date,
    status_ordering smallint NOT NULL
);


ALTER TABLE public.ordering OWNER TO postgres;

--
-- TOC entry 4976 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE ordering; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.ordering IS '1-Создан
2-В обработке
3-В работе
4-Авто прибыл
5-Ожидает оплаты
6-Оплачен
7-Отменен';


--
-- TOC entry 225 (class 1259 OID 33113)
-- Name: ordering_id_ordering_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ordering_id_ordering_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ordering_id_ordering_seq OWNER TO postgres;

--
-- TOC entry 4977 (class 0 OID 0)
-- Dependencies: 225
-- Name: ordering_id_ordering_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ordering_id_ordering_seq OWNED BY public.ordering.id_ordering;


--
-- TOC entry 228 (class 1259 OID 33124)
-- Name: part; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.part (
    id_part integer NOT NULL,
    color_part character varying(100) NOT NULL,
    type_part smallint NOT NULL,
    cost_part numeric(10,2) NOT NULL,
    name_part character varying(255) NOT NULL
);


ALTER TABLE public.part OWNER TO postgres;

--
-- TOC entry 4978 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE part; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.part IS '1-Масло моторное
2-Масло трансмиссионное
3-Антифриз
4-Шины летние
5-Шины зимние
6-Тормозные колодки
7-Аккумулятор
8-Фильтр масляный
9-Фильтр воздушный
10-Фильтр салона
11-Фильтр топливный
12-Сцепление
13-Амортизаторы
14-Поршни
15-Стартер
16-Генератор
17-Свечи зажигания
18-Лямбда-зонд
19-Катализатор
20-Топливный насос';


--
-- TOC entry 227 (class 1259 OID 33123)
-- Name: part_id_part_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.part_id_part_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.part_id_part_seq OWNER TO postgres;

--
-- TOC entry 4979 (class 0 OID 0)
-- Dependencies: 227
-- Name: part_id_part_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.part_id_part_seq OWNED BY public.part.id_part;


--
-- TOC entry 229 (class 1259 OID 33131)
-- Name: relate; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.relate (
    vin character varying(17) NOT NULL,
    id_part integer NOT NULL
);


ALTER TABLE public.relate OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 33140)
-- Name: request; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.request (
    id_request integer NOT NULL,
    id_supplier integer NOT NULL,
    id_manager integer,
    data_registration date NOT NULL,
    status_request smallint NOT NULL,
    cost_request numeric(10,2) NOT NULL,
    data_action date,
    action_type smallint
);


ALTER TABLE public.request OWNER TO postgres;

--
-- TOC entry 4980 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE request; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.request IS '1-В работе
2-Отменена
3-Выполнена
1-Удаление
2-Изменение
3-Добавление
4-Просмотр';


--
-- TOC entry 230 (class 1259 OID 33139)
-- Name: request_id_request_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.request_id_request_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.request_id_request_seq OWNER TO postgres;

--
-- TOC entry 4981 (class 0 OID 0)
-- Dependencies: 230
-- Name: request_id_request_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.request_id_request_seq OWNED BY public.request.id_request;


--
-- TOC entry 233 (class 1259 OID 33150)
-- Name: supplier; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.supplier (
    id_supplier integer NOT NULL,
    name_supplier character varying(255) NOT NULL,
    login_supplier character varying(100),
    password_supplier character varying(256)
);


ALTER TABLE public.supplier OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 33149)
-- Name: supplier_id_supplier_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.supplier_id_supplier_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.supplier_id_supplier_seq OWNER TO postgres;

--
-- TOC entry 4982 (class 0 OID 0)
-- Dependencies: 232
-- Name: supplier_id_supplier_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.supplier_id_supplier_seq OWNED BY public.supplier.id_supplier;


--
-- TOC entry 4746 (class 2604 OID 33077)
-- Name: client id_client; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client ALTER COLUMN id_client SET DEFAULT nextval('public.client_id_client_seq'::regclass);


--
-- TOC entry 4747 (class 2604 OID 33092)
-- Name: manager id_manager; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manager ALTER COLUMN id_manager SET DEFAULT nextval('public.manager_id_manager_seq'::regclass);


--
-- TOC entry 4748 (class 2604 OID 33100)
-- Name: model id_model; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.model ALTER COLUMN id_model SET DEFAULT nextval('public.model_id_model_seq'::regclass);


--
-- TOC entry 4749 (class 2604 OID 33117)
-- Name: ordering id_ordering; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ordering ALTER COLUMN id_ordering SET DEFAULT nextval('public.ordering_id_ordering_seq'::regclass);


--
-- TOC entry 4750 (class 2604 OID 33127)
-- Name: part id_part; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.part ALTER COLUMN id_part SET DEFAULT nextval('public.part_id_part_seq'::regclass);


--
-- TOC entry 4751 (class 2604 OID 33143)
-- Name: request id_request; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.request ALTER COLUMN id_request SET DEFAULT nextval('public.request_id_request_seq'::regclass);


--
-- TOC entry 4752 (class 2604 OID 33153)
-- Name: supplier id_supplier; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.supplier ALTER COLUMN id_supplier SET DEFAULT nextval('public.supplier_id_supplier_seq'::regclass);


--
-- TOC entry 4952 (class 0 OID 33074)
-- Dependencies: 218
-- Data for Name: client; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.client VALUES (15, '83523453425', 'Васильев Василий Васильевич', '4218 135700', '', '');
INSERT INTO public.client VALUES (34, '83434343434', 'Лаб Лабудаев Лабуда', '2424 242424', 'admin1232', 'admin123');
INSERT INTO public.client VALUES (36, '89913437878', 'Лабуда Лаб Лабудаев', '4218 789054', 'admin12364', 'admin123');
INSERT INTO public.client VALUES (11, '89934567899', 'Навиков Дмитрий Дмитриевич', '4218 135699', NULL, NULL);
INSERT INTO public.client VALUES (13, '89934567901', 'Попов Павел Павловича', '4218 135701', NULL, NULL);
INSERT INTO public.client VALUES (9, '89934567889', 'Максимов Максим Максимович', '4218 867677', NULL, NULL);
INSERT INTO public.client VALUES (24, '89913431444', 'Богданов Борис Борисёович', '4218 135712', NULL, NULL);
INSERT INTO public.client VALUES (31, '89913433434', 'Максимов Максим Максимович', '4218 134378', NULL, NULL);
INSERT INTO public.client VALUES (19, '89934567907', 'Зайцев Зиновий Зиновьевич', '4218 135707', NULL, NULL);
INSERT INTO public.client VALUES (22, '89934567910', 'Павлов Пётр Петрович', '4218 135710', NULL, NULL);
INSERT INTO public.client VALUES (32, '89913433434', 'Максимов Максим Максимович', '4218 134378', NULL, NULL);
INSERT INTO public.client VALUES (6, '89913431617', 'Антонов Антон Антовоич', '4218 134567', NULL, NULL);
INSERT INTO public.client VALUES (18, '89934566122', 'Зайцев Зиновий Зиновьевич', '4218 111177', NULL, NULL);
INSERT INTO public.client VALUES (12, '89934567901', 'Васильев Василий Васильевич', '4218 135700', NULL, NULL);
INSERT INTO public.client VALUES (16, '89934567912', 'Павлов Пётр Петрович', '4218 135722', NULL, NULL);
INSERT INTO public.client VALUES (2, '89913431811', 'Абулдаева', '4218 134982', NULL, NULL);
INSERT INTO public.client VALUES (21, '89934567912', 'Павлов Пётр Петрович', '4218 135700', NULL, NULL);
INSERT INTO public.client VALUES (25, '89934567913', 'Воробьёв Владимир Владимирович', '4218 135713', NULL, NULL);
INSERT INTO public.client VALUES (26, '89934567914', 'Фролов Фёдор Фёдорович', '4218 135714', NULL, NULL);
INSERT INTO public.client VALUES (14, '89934567902', 'Смирнов Семён Семёнович', '4218 135702', NULL, NULL);
INSERT INTO public.client VALUES (23, '83232324515', 'Виноградов Василий Викторович', '4218 135777', NULL, NULL);
INSERT INTO public.client VALUES (17, '89934567905', 'Орлов Олег Олеговича', '4218 135705', NULL, NULL);
INSERT INTO public.client VALUES (27, '89934567915', 'Карпов Константин Константинович', '4218 135715', NULL, NULL);
INSERT INTO public.client VALUES (3, '89934567891', 'Богдаasнов Борис Борисёович', '4218 135691', 'admin', 'admin');
INSERT INTO public.client VALUES (8, '89913431444', 'Богданов Борис Борисёович', '4218 777777', NULL, NULL);
INSERT INTO public.client VALUES (20, '89934567908', 'Волков Владимир Владимирович', '4218 135708', '', '');
INSERT INTO public.client VALUES (4, '89934567891', 'Богдаasнов Борис Борисёович', '4218 135691', 'admin1', 'admin1');
INSERT INTO public.client VALUES (1, '89913431611', 'Лапов лап Лаповичt', '4218 145786', NULL, NULL);
INSERT INTO public.client VALUES (29, '89913431414', 'Иванов Инвава Ларов', '4218 134343', 'ad', 'ad');
INSERT INTO public.client VALUES (5, '89913431512', 'Васильев Василий Васильевич', '4218 134599', NULL, NULL);
INSERT INTO public.client VALUES (10, '89934567898', 'Кузнецов Николай Николаевич', '4218 135698', NULL, NULL);


--
-- TOC entry 4953 (class 0 OID 33081)
-- Dependencies: 219
-- Data for Name: configuration; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.configuration VALUES ('VIN00000000000014', 14, 'Basic Plus');
INSERT INTO public.configuration VALUES ('VIN00000000000015', 15, 'Performance Pack');
INSERT INTO public.configuration VALUES ('VIN00000000000016', 16, 'Comfort Plus');
INSERT INTO public.configuration VALUES ('VIN00000000000017', 17, 'Eco Plus');
INSERT INTO public.configuration VALUES ('VIN00000000000018', 18, 'Tech Premium');
INSERT INTO public.configuration VALUES ('VIN00000000000019', 19, 'Off-Road Extreme');
INSERT INTO public.configuration VALUES ('VIN00000000000020', 20, 'Standard Plus');
INSERT INTO public.configuration VALUES ('VIN00000000000021', 21, 'Advanced');
INSERT INTO public.configuration VALUES ('VIN00000000000022', 22, 'Family Pack');
INSERT INTO public.configuration VALUES ('VIN00000000000023', 23, 'Touring');
INSERT INTO public.configuration VALUES ('VIN00000000000024', 24, 'Executive');
INSERT INTO public.configuration VALUES ('VIN00000000000025', 25, 'Track Edition');
INSERT INTO public.configuration VALUES ('VIN00000000000004', 4, 'Premium1');
INSERT INTO public.configuration VALUES ('VIN00000000000005', 5, 'Basic');
INSERT INTO public.configuration VALUES ('VIN00000000000006', 6, 'Performance');
INSERT INTO public.configuration VALUES ('VIN00000000000008', 8, 'Eco1');
INSERT INTO public.configuration VALUES ('VIN00000000000009', 9, 'Tech Pack1');
INSERT INTO public.configuration VALUES ('ASD12345678910111', 13, 'LAUZ');
INSERT INTO public.configuration VALUES ('VIN00000000000002', 2, 'SAME');
INSERT INTO public.configuration VALUES ('VIN00000000000010', 10, 'Off-Roadd');
INSERT INTO public.configuration VALUES ('VIN00000000000011', 11, 'Sport Plus777');
INSERT INTO public.configuration VALUES ('VIN00000000000012', 12, 'Luxury Plus1');
INSERT INTO public.configuration VALUES ('VIN46346363463636', 23, 'ДФЗ');


--
-- TOC entry 4955 (class 0 OID 33089)
-- Dependencies: 221
-- Data for Name: manager; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.manager VALUES (26, 'Зайцев Андрей Андреевич', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (1, 'Иванов Иван Иванович', '2024-12-26', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (21, 'Крылов Кирилл Кирилвввлович', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (10, 'Орлов Олег Олегович', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (22, 'Воробьёв Владимир Владимирович', '2024-12-14', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (25, 'Жуков Александр Александрович', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (5, 'Михайлов Михаил Михайлович', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (8, 'Максимов Максим Максимович', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (24, 'Мельников Михаил Михайлович', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (23, 'Абрамов', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (17, 'Богданов Борис Борисович', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (18, 'Фролов Фёдор Фёдорович', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (9, 'Кузьмин Кирилл', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (14, 'Павлов Андрей Борисович', '2023-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (19, 'Беляев Федор Васильевич', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (6, 'Богданов Борис Борисович', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (20, 'Беляев Борис Борисовиыч', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (11, 'Зайцев Зиновий Зинович', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (16, 'Андрей Андреев Андреевич', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (4, 'Кузнецов Николай Николаевич', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (27, 'Егоров Евгений Евгеньевич', '2025-01-03', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (13, 'Волков Владимир Владимирович', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (7, 'Александров Александр Александрович', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (2, 'Богданов Борис Борисович', '2024-12-12', 'admin123', 'admin123', 'admin');
INSERT INTO public.manager VALUES (3, 'Кузнецов Николай Николаевич', '2024-12-12', 'manager', 'manager', 'manager');
INSERT INTO public.manager VALUES (15, 'Егоров Евгений Евгеньевич666', '2024-12-12', NULL, NULL, NULL);
INSERT INTO public.manager VALUES (28, 'Лабуда Лаб Лабудаев', '2024-12-12', 'admin1236', 'admin123', 'admin');
INSERT INTO public.manager VALUES (29, 'Лабуда Лаб Лабудаев', '2024-12-12', 'admin123222', 'admin123', 'admin');


--
-- TOC entry 4957 (class 0 OID 33097)
-- Dependencies: 223
-- Data for Name: model; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.model VALUES (24, 'Honda Accord', '2024', '2023', 'PQR456789');
INSERT INTO public.model VALUES (25, 'Toyota Camry', '1982', '2023', 'STU567890');
INSERT INTO public.model VALUES (20, 'Ford Mustang', '2024', '2023', 'TZA232323');
INSERT INTO public.model VALUES (21, 'Chevrolet Tahoe', '1995', '2023', 'GHI123456');
INSERT INTO public.model VALUES (22, 'Dodge Charger', '2024', '2023', 'JKL234567');
INSERT INTO public.model VALUES (3, 'Toy1', '1990', '2025', 'GHY232323');
INSERT INTO public.model VALUES (14, 'Hyundai Elantra', '2010', '2013', 'SDS232323');
INSERT INTO public.model VALUES (12, 'Mazda MX-51', '1983', '2023', 'HIJ234567');
INSERT INTO public.model VALUES (4, 'Honda Civic1', '2021', '2023', 'JKL456789');
INSERT INTO public.model VALUES (2, 'FOLD', '2004', '2009', 'DEF234567');
INSERT INTO public.model VALUES (11, 'Porsche 911', '1964', '2023', 'EFG123451');
INSERT INTO public.model VALUES (10, 'Chevrolet Camaro', '1967', '2023', 'BCD012341');
INSERT INTO public.model VALUES (5, 'BMW 3 Series', '2021', '2023', 'MNO567890');
INSERT INTO public.model VALUES (13, 'Subaru Impreza', '1992', '2023', 'KLM345678');
INSERT INTO public.model VALUES (6, 'Audi A4', '2004', '2023', 'PQR678901');
INSERT INTO public.model VALUES (8, 'Volkswagen Golf111', '1974', '2023', 'VWX890121');
INSERT INTO public.model VALUES (26, 'LAUZEL', '2021', '2024', 'YZA123456');
INSERT INTO public.model VALUES (23, 'Volkswagen Passat1', '1971', '2021', 'MNO3456781');
INSERT INTO public.model VALUES (27, 'LAS', '2024', '2020', 'PQE234563');
INSERT INTO public.model VALUES (15, 'Tesla Model S', '2024', '2023', '232332');
INSERT INTO public.model VALUES (16, 'Nissan Altima', '2056', '2023', 'SDS232323');
INSERT INTO public.model VALUES (17, 'Mitsubishi Lancer1', '2021', '2025', 'UVW789012');
INSERT INTO public.model VALUES (18, 'Kia Sportage', '2021', '2024', 'XYZ890123');
INSERT INTO public.model VALUES (19, 'Jeep Wrangler', '1986', '2023', 'ABC901234');
INSERT INTO public.model VALUES (9, 'Mercedes-Benz C-Class12', '1993', '2023', 'YZA901231');


--
-- TOC entry 4958 (class 0 OID 33104)
-- Dependencies: 224
-- Data for Name: order_parts; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.order_parts VALUES (17, 17, 17, 3);
INSERT INTO public.order_parts VALUES (18, 18, 18, 16);
INSERT INTO public.order_parts VALUES (13, 13, 13, 20);
INSERT INTO public.order_parts VALUES (9, 9, 9, 90);
INSERT INTO public.order_parts VALUES (19, 19, 19, 4);
INSERT INTO public.order_parts VALUES (3, 3, 3, 10);
INSERT INTO public.order_parts VALUES (4, 4, 4, 10);
INSERT INTO public.order_parts VALUES (5, 5, 5, 15);
INSERT INTO public.order_parts VALUES (10, 10, 10, 2);
INSERT INTO public.order_parts VALUES (11, 11, 11, 9);
INSERT INTO public.order_parts VALUES (12, 12, 12, 777);
INSERT INTO public.order_parts VALUES (52, 11, 14, 2);
INSERT INTO public.order_parts VALUES (52, 14, 14, 4);
INSERT INTO public.order_parts VALUES (52, 15, 14, 1);
INSERT INTO public.order_parts VALUES (53, 11, 15, 1);
INSERT INTO public.order_parts VALUES (53, 14, 15, 2);
INSERT INTO public.order_parts VALUES (55, 17, 26, 4);
INSERT INTO public.order_parts VALUES (55, 18, 26, 5);
INSERT INTO public.order_parts VALUES (55, 13, 26, 3);
INSERT INTO public.order_parts VALUES (56, 11, 27, 1);
INSERT INTO public.order_parts VALUES (56, 14, 27, 3);
INSERT INTO public.order_parts VALUES (57, 11, 28, 1);
INSERT INTO public.order_parts VALUES (57, 14, 28, 2);
INSERT INTO public.order_parts VALUES (58, 11, 29, 1);


--
-- TOC entry 4960 (class 0 OID 33114)
-- Dependencies: 226
-- Data for Name: ordering; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.ordering VALUES (21, 21, 21, '2025-01-13', NULL, 4);
INSERT INTO public.ordering VALUES (23, 23, 23, '2025-01-15', '2025-01-16', 6);
INSERT INTO public.ordering VALUES (24, 24, 24, '2025-01-16', NULL, 2);
INSERT INTO public.ordering VALUES (2, 2, 2, '2024-12-12', '2024-06-06', 6);
INSERT INTO public.ordering VALUES (5, 5, 5, '2024-12-28', '2024-12-29', 6);
INSERT INTO public.ordering VALUES (6, 6, 6, '2024-12-29', '2024-12-30', 6);
INSERT INTO public.ordering VALUES (9, 9, 9, '2025-01-01', '1970-01-01', 1);
INSERT INTO public.ordering VALUES (13, 13, 13, '2025-01-04', '1970-01-01', 1);
INSERT INTO public.ordering VALUES (16, 16, 16, '2025-01-08', '2000-12-12', 1);
INSERT INTO public.ordering VALUES (18, 18, 18, '2025-01-10', NULL, 7);
INSERT INTO public.ordering VALUES (25, 25, 25, '2025-01-17', NULL, 7);
INSERT INTO public.ordering VALUES (22, 22, 22, '2025-01-14', NULL, 7);
INSERT INTO public.ordering VALUES (19, 19, 19, '2024-12-12', '2024-12-12', 5);
INSERT INTO public.ordering VALUES (3, 3, 3, '2024-12-16', '2024-12-12', 6);
INSERT INTO public.ordering VALUES (1, 1, 1, '2024-12-12', NULL, 7);
INSERT INTO public.ordering VALUES (10, 10, 10, '2025-01-02', '2025-01-03', 6);
INSERT INTO public.ordering VALUES (4, 4, 4, '2024-12-27', '2025-01-07', 1);
INSERT INTO public.ordering VALUES (17, 17, 17, '2025-01-09', NULL, 7);
INSERT INTO public.ordering VALUES (12, NULL, 12, '2025-01-04', '2025-01-05', 6);
INSERT INTO public.ordering VALUES (52, 2, 2, '2025-06-12', NULL, 1);
INSERT INTO public.ordering VALUES (53, 2, 2, '2025-06-12', NULL, 1);
INSERT INTO public.ordering VALUES (55, 2, 2, '2025-06-12', NULL, 1);
INSERT INTO public.ordering VALUES (56, 2, 31, '2025-06-12', NULL, 1);
INSERT INTO public.ordering VALUES (58, 2, 24, '2025-06-12', NULL, 1);
INSERT INTO public.ordering VALUES (57, NULL, 3, '2025-06-12', NULL, 7);
INSERT INTO public.ordering VALUES (11, 11, 11, '2025-01-03', '1970-01-01', 7);


--
-- TOC entry 4962 (class 0 OID 33124)
-- Dependencies: 228
-- Data for Name: part; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.part VALUES (11, 'Каие', 11, 600.00, 'Фильтр топливный');
INSERT INTO public.part VALUES (14, 'Белый', 14, 2500.00, 'Поршень');
INSERT INTO public.part VALUES (15, 'Синий', 15, 7000.00, 'Стартеры');
INSERT INTO public.part VALUES (17, 'Черный', 17, 2000.00, 'Свечи зажигании');
INSERT INTO public.part VALUES (18, 'Серая', 3, 4522.00, 'Лямбда-зонды');
INSERT INTO public.part VALUES (19, 'Белый', 3, 12000.00, 'Катализатор');
INSERT INTO public.part VALUES (20, 'Черный', 20, 3500.00, 'Топливный насосы');
INSERT INTO public.part VALUES (2, 'Зеля', 3, 1200.00, 'Анти');
INSERT INTO public.part VALUES (1, 'Белы', 3, 1000.00, 'Маслоf');
INSERT INTO public.part VALUES (3, 'Красныt', 3, 2500.00, 'Стартер');
INSERT INTO public.part VALUES (6, 'Черные', 6, 1000.00, 'Тормозные колодки');
INSERT INTO public.part VALUES (13, 'Красная', 13, 5500.00, 'Амортизаторы');
INSERT INTO public.part VALUES (4, 'Черная', 4, 3500.00, 'Шины летние');
INSERT INTO public.part VALUES (5, 'Белая', 5, 4000.00, 'Шины зимние');
INSERT INTO public.part VALUES (10, 'Зеленs', 10, 300.00, 'Фильтр салон');
INSERT INTO public.part VALUES (16, 'вава', 16, 6000.00, 'вава');
INSERT INTO public.part VALUES (7, 'Краснsq', 7, 8000.00, 'Аккумулятор');
INSERT INTO public.part VALUES (21, 'Синяя', 2, 2232.00, 'Маслянка');
INSERT INTO public.part VALUES (12, 'Серый', 12, 4000.00, 'Сцепление');
INSERT INTO public.part VALUES (9, 'Синяя4', 8, 66666.00, 'Фильтр воздушный1');
INSERT INTO public.part VALUES (22, 'Фиолка', 5, 200.00, 'Фильтр');
INSERT INTO public.part VALUES (23, 'Фиолка', 8, 255.00, 'Фильтр');


--
-- TOC entry 4963 (class 0 OID 33131)
-- Dependencies: 229
-- Data for Name: relate; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.relate VALUES ('VIN00000000000004', 10);
INSERT INTO public.relate VALUES ('VIN00000000000004', 11);
INSERT INTO public.relate VALUES ('VIN00000000000004', 12);
INSERT INTO public.relate VALUES ('VIN00000000000005', 13);
INSERT INTO public.relate VALUES ('VIN00000000000005', 14);
INSERT INTO public.relate VALUES ('VIN00000000000005', 15);
INSERT INTO public.relate VALUES ('VIN00000000000006', 16);
INSERT INTO public.relate VALUES ('VIN00000000000006', 17);
INSERT INTO public.relate VALUES ('VIN00000000000006', 18);
INSERT INTO public.relate VALUES ('VIN00000000000008', 1);
INSERT INTO public.relate VALUES ('VIN00000000000008', 2);
INSERT INTO public.relate VALUES ('VIN00000000000008', 3);
INSERT INTO public.relate VALUES ('VIN00000000000009', 4);
INSERT INTO public.relate VALUES ('VIN00000000000009', 5);


--
-- TOC entry 4965 (class 0 OID 33140)
-- Dependencies: 231
-- Data for Name: request; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.request VALUES (9, 15, 1, '2022-12-12', 1, 2222200.00, '2025-06-10', 2);
INSERT INTO public.request VALUES (2, 12, 2, '2025-06-27', 2, 1000.00, '2025-06-10', 2);
INSERT INTO public.request VALUES (12, 12, NULL, '2025-01-04', 2, 2620.00, '2025-06-11', 2);
INSERT INTO public.request VALUES (14, 10, 2, '2025-06-12', 1, 18200.00, '2025-06-12', 3);
INSERT INTO public.request VALUES (15, 17, 2, '2025-06-12', 1, 5600.00, '2025-06-12', 3);
INSERT INTO public.request VALUES (10, 10, 10, '2025-01-02', 1, 2600.00, '2025-01-05', 2);
INSERT INTO public.request VALUES (13, 13, 13, '2025-01-05', 2, 2677.00, '2025-01-05', 2);
INSERT INTO public.request VALUES (17, 17, 17, '2025-01-09', 2, 2600.00, '2025-01-05', 2);
INSERT INTO public.request VALUES (18, 18, 18, '2025-01-10', 1, 2600.00, '2025-01-05', 2);
INSERT INTO public.request VALUES (19, 19, 19, '2025-01-11', 3, 2600.00, '2025-01-06', 2);
INSERT INTO public.request VALUES (11, 11, 11, '2024-01-03', 1, 2600.00, '2025-01-06', 2);
INSERT INTO public.request VALUES (20, 20, 20, '2025-01-12', 2, 2600.00, '2025-01-06', 2);
INSERT INTO public.request VALUES (21, 21, 21, '2025-01-13', 1, 2600.00, '2025-01-06', 2);
INSERT INTO public.request VALUES (22, 22, 22, '2025-01-14', 2, 2600.00, '2025-01-06', 2);
INSERT INTO public.request VALUES (26, 3, 2, '2025-06-12', 1, 47110.00, '2025-06-12', 3);
INSERT INTO public.request VALUES (24, 24, 24, '2025-01-16', 1, 2600.00, '2025-01-07', 2);
INSERT INTO public.request VALUES (23, 23, 23, '2024-01-15', 2, 2650.00, '2025-01-07', 2);
INSERT INTO public.request VALUES (4, 4, 4, '2024-12-27', 1, 2600.00, '2025-01-07', 2);
INSERT INTO public.request VALUES (7, 7, 7, '2024-12-30', 1, 2600.00, '2025-01-07', 2);
INSERT INTO public.request VALUES (25, 25, 25, '2025-01-17', 3, 2600.00, '2025-01-07', 2);
INSERT INTO public.request VALUES (3, 3, 3, '2024-12-26', 1, 2600.00, '2025-01-07', 2);
INSERT INTO public.request VALUES (5, 5, 5, '2024-12-28', 1, 2600.00, '2025-01-07', 2);
INSERT INTO public.request VALUES (8, 8, 8, '2024-12-31', 1, 2600.00, '2025-01-08', 2);
INSERT INTO public.request VALUES (27, 2, 2, '2025-06-12', 1, 8100.00, '2025-06-12', 3);
INSERT INTO public.request VALUES (28, 18, NULL, '2025-06-12', 1, 5600.00, '2025-06-12', 3);
INSERT INTO public.request VALUES (29, 18, 2, '2025-06-12', 1, 600.00, '2025-06-12', 3);


--
-- TOC entry 4967 (class 0 OID 33150)
-- Dependencies: 233
-- Data for Name: supplier; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.supplier VALUES (12, 'ИПА', NULL, NULL);
INSERT INTO public.supplier VALUES (33, 'JK OFF', NULL, NULL);
INSERT INTO public.supplier VALUES (11, 'ОООО', NULL, NULL);
INSERT INTO public.supplier VALUES (14, 'Эту изменил', NULL, NULL);
INSERT INTO public.supplier VALUES (24, 'ООО123', NULL, NULL);
INSERT INTO public.supplier VALUES (23, 'ЗЛАЛf', NULL, NULL);
INSERT INTO public.supplier VALUES (2, 'Sun12', NULL, NULL);
INSERT INTO public.supplier VALUES (6, 'ИПs1', NULL, NULL);
INSERT INTO public.supplier VALUES (15, 'ООО1', NULL, NULL);
INSERT INTO public.supplier VALUES (4, 'ООО', NULL, NULL);
INSERT INTO public.supplier VALUES (13, 'ЗАО', NULL, NULL);
INSERT INTO public.supplier VALUES (7, 'ИПs', NULL, NULL);
INSERT INTO public.supplier VALUES (25, 'ИПА', NULL, NULL);
INSERT INTO public.supplier VALUES (3, 'adqwr551', NULL, NULL);
INSERT INTO public.supplier VALUES (5, 'ЗАО JJ', NULL, NULL);
INSERT INTO public.supplier VALUES (8, 'ООО', NULL, NULL);
INSERT INTO public.supplier VALUES (10, 'ФокутИК', NULL, NULL);
INSERT INTO public.supplier VALUES (17, 'ИП', NULL, NULL);
INSERT INTO public.supplier VALUES (18, 'ОООО00', NULL, NULL);
INSERT INTO public.supplier VALUES (19, 'ЗЛАО', NULL, NULL);
INSERT INTO public.supplier VALUES (20, 'ООО0', NULL, NULL);
INSERT INTO public.supplier VALUES (21, 'ИПОЛАН', NULL, NULL);
INSERT INTO public.supplier VALUES (22, 'ООО0', NULL, NULL);
INSERT INTO public.supplier VALUES (9, 'ЗАСИК', NULL, NULL);
INSERT INTO public.supplier VALUES (1, 'АвтоАа', NULL, NULL);


--
-- TOC entry 4983 (class 0 OID 0)
-- Dependencies: 217
-- Name: client_id_client_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.client_id_client_seq', 36, true);


--
-- TOC entry 4984 (class 0 OID 0)
-- Dependencies: 220
-- Name: manager_id_manager_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.manager_id_manager_seq', 29, true);


--
-- TOC entry 4985 (class 0 OID 0)
-- Dependencies: 222
-- Name: model_id_model_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.model_id_model_seq', 27, true);


--
-- TOC entry 4986 (class 0 OID 0)
-- Dependencies: 225
-- Name: ordering_id_ordering_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ordering_id_ordering_seq', 58, true);


--
-- TOC entry 4987 (class 0 OID 0)
-- Dependencies: 227
-- Name: part_id_part_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.part_id_part_seq', 23, true);


--
-- TOC entry 4988 (class 0 OID 0)
-- Dependencies: 230
-- Name: request_id_request_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.request_id_request_seq', 29, true);


--
-- TOC entry 4989 (class 0 OID 0)
-- Dependencies: 232
-- Name: supplier_id_supplier_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.supplier_id_supplier_seq', 35, true);


--
-- TOC entry 4768 (class 2606 OID 33108)
-- Name: order_parts PK_ORDER PARTS; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_parts
    ADD CONSTRAINT "PK_ORDER PARTS" PRIMARY KEY (id_ordering, id_part);


--
-- TOC entry 4755 (class 2606 OID 33079)
-- Name: client pk_client; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT pk_client PRIMARY KEY (id_client);


--
-- TOC entry 4759 (class 2606 OID 33085)
-- Name: configuration pk_configuration; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuration
    ADD CONSTRAINT pk_configuration PRIMARY KEY (vin);


--
-- TOC entry 4762 (class 2606 OID 33094)
-- Name: manager pk_manager; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manager
    ADD CONSTRAINT pk_manager PRIMARY KEY (id_manager);


--
-- TOC entry 4765 (class 2606 OID 33102)
-- Name: model pk_model; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.model
    ADD CONSTRAINT pk_model PRIMARY KEY (id_model);


--
-- TOC entry 4775 (class 2606 OID 33119)
-- Name: ordering pk_ordering; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ordering
    ADD CONSTRAINT pk_ordering PRIMARY KEY (id_ordering);


--
-- TOC entry 4779 (class 2606 OID 33129)
-- Name: part pk_part; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.part
    ADD CONSTRAINT pk_part PRIMARY KEY (id_part);


--
-- TOC entry 4781 (class 2606 OID 33135)
-- Name: relate pk_relate; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.relate
    ADD CONSTRAINT pk_relate PRIMARY KEY (vin, id_part);


--
-- TOC entry 4788 (class 2606 OID 33145)
-- Name: request pk_request; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.request
    ADD CONSTRAINT pk_request PRIMARY KEY (id_request);


--
-- TOC entry 4791 (class 2606 OID 33155)
-- Name: supplier pk_supplier; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.supplier
    ADD CONSTRAINT pk_supplier PRIMARY KEY (id_supplier);


--
-- TOC entry 4766 (class 1259 OID 33109)
-- Name: Order parts_PK; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Order parts_PK" ON public.order_parts USING btree (id_ordering, id_part);


--
-- TOC entry 4785 (class 1259 OID 33147)
-- Name: accept_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accept_fk ON public.request USING btree (id_supplier);


--
-- TOC entry 4753 (class 1259 OID 33080)
-- Name: client_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX client_pk ON public.client USING btree (id_client);


--
-- TOC entry 4756 (class 1259 OID 33086)
-- Name: configuration_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX configuration_pk ON public.configuration USING btree (vin);


--
-- TOC entry 4757 (class 1259 OID 33087)
-- Name: contain_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX contain_fk ON public.configuration USING btree (id_model);


--
-- TOC entry 4769 (class 1259 OID 33111)
-- Name: containing_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX containing_fk ON public.order_parts USING btree (id_request);


--
-- TOC entry 4772 (class 1259 OID 33122)
-- Name: does_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX does_fk ON public.ordering USING btree (id_client);


--
-- TOC entry 4770 (class 1259 OID 33112)
-- Name: exists_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX exists_fk ON public.order_parts USING btree (id_ordering);


--
-- TOC entry 4771 (class 1259 OID 33110)
-- Name: include_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX include_fk ON public.order_parts USING btree (id_part);


--
-- TOC entry 4786 (class 1259 OID 33148)
-- Name: interaction_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX interaction_fk ON public.request USING btree (id_manager);


--
-- TOC entry 4760 (class 1259 OID 33095)
-- Name: manager_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX manager_pk ON public.manager USING btree (id_manager);


--
-- TOC entry 4763 (class 1259 OID 33103)
-- Name: model_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX model_pk ON public.model USING btree (id_model);


--
-- TOC entry 4773 (class 1259 OID 33120)
-- Name: ordering_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ordering_pk ON public.ordering USING btree (id_ordering);


--
-- TOC entry 4777 (class 1259 OID 33130)
-- Name: part_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX part_pk ON public.part USING btree (id_part);


--
-- TOC entry 4782 (class 1259 OID 33137)
-- Name: relate2_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX relate2_fk ON public.relate USING btree (id_part);


--
-- TOC entry 4783 (class 1259 OID 33138)
-- Name: relate_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX relate_fk ON public.relate USING btree (vin);


--
-- TOC entry 4784 (class 1259 OID 33136)
-- Name: relate_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX relate_pk ON public.relate USING btree (vin, id_part);


--
-- TOC entry 4789 (class 1259 OID 33146)
-- Name: request_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX request_pk ON public.request USING btree (id_request);


--
-- TOC entry 4792 (class 1259 OID 33156)
-- Name: supplier_pk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX supplier_pk ON public.supplier USING btree (id_supplier);


--
-- TOC entry 4776 (class 1259 OID 33121)
-- Name: take_it_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX take_it_fk ON public.ordering USING btree (id_manager);


--
-- TOC entry 4803 (class 2620 OID 41276)
-- Name: ordering trg_cancel_unpaid_orders; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_cancel_unpaid_orders BEFORE INSERT OR UPDATE ON public.ordering FOR EACH ROW EXECUTE FUNCTION public.cancel_unpaid_orders();


--
-- TOC entry 4804 (class 2620 OID 41268)
-- Name: request trg_handle_request_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_handle_request_insert BEFORE INSERT ON public.request FOR EACH ROW EXECUTE FUNCTION public.handle_request_activity();


--
-- TOC entry 4805 (class 2620 OID 41269)
-- Name: request trg_handle_request_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_handle_request_update BEFORE UPDATE ON public.request FOR EACH ROW EXECUTE FUNCTION public.handle_request_activity();


--
-- TOC entry 4794 (class 2606 OID 33162)
-- Name: order_parts FK_ORDER PA_CONTAININ_REQUEST; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_parts
    ADD CONSTRAINT "FK_ORDER PA_CONTAININ_REQUEST" FOREIGN KEY (id_request) REFERENCES public.request(id_request) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4795 (class 2606 OID 33167)
-- Name: order_parts FK_ORDER PA_EXISTS_ORDERING; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_parts
    ADD CONSTRAINT "FK_ORDER PA_EXISTS_ORDERING" FOREIGN KEY (id_ordering) REFERENCES public.ordering(id_ordering) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4796 (class 2606 OID 33172)
-- Name: order_parts FK_ORDER PA_INCLUDE_PART; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_parts
    ADD CONSTRAINT "FK_ORDER PA_INCLUDE_PART" FOREIGN KEY (id_part) REFERENCES public.part(id_part) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4793 (class 2606 OID 33157)
-- Name: configuration fk_configur_contain_model; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuration
    ADD CONSTRAINT fk_configur_contain_model FOREIGN KEY (id_model) REFERENCES public.model(id_model) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4797 (class 2606 OID 33177)
-- Name: ordering fk_ordering_does_client; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ordering
    ADD CONSTRAINT fk_ordering_does_client FOREIGN KEY (id_client) REFERENCES public.client(id_client) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4798 (class 2606 OID 33182)
-- Name: ordering fk_ordering_take_it_manager; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ordering
    ADD CONSTRAINT fk_ordering_take_it_manager FOREIGN KEY (id_manager) REFERENCES public.manager(id_manager) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4799 (class 2606 OID 33192)
-- Name: relate fk_relate_relate2_part; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.relate
    ADD CONSTRAINT fk_relate_relate2_part FOREIGN KEY (id_part) REFERENCES public.part(id_part) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4800 (class 2606 OID 33187)
-- Name: relate fk_relate_relate_configur; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.relate
    ADD CONSTRAINT fk_relate_relate_configur FOREIGN KEY (vin) REFERENCES public.configuration(vin) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4801 (class 2606 OID 33197)
-- Name: request fk_request_accept_supplier; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.request
    ADD CONSTRAINT fk_request_accept_supplier FOREIGN KEY (id_supplier) REFERENCES public.supplier(id_supplier) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4802 (class 2606 OID 33202)
-- Name: request fk_request_interacti_manager; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.request
    ADD CONSTRAINT fk_request_interacti_manager FOREIGN KEY (id_manager) REFERENCES public.manager(id_manager) ON UPDATE RESTRICT ON DELETE RESTRICT;


-- Completed on 2025-06-16 14:24:15

--
-- PostgreSQL database dump complete
--

