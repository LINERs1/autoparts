
BEGIN
  -- Проверяем, если заказ был создан более недели назад и не оплачен
  IF NEW.datepay_ordering IS NULL AND NEW.date_ordering <= CURRENT_DATE - INTERVAL '7 days' THEN
    -- Обновляем статус на 'Отменен'
    NEW.status_ordering := '7';
  END IF;
  RETURN NEW;
END;
