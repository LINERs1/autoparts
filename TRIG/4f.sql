
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
