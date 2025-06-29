
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
