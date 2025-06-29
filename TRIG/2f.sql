
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
