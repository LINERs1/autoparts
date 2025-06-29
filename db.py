from flask import Flask, jsonify, Response, request, send_from_directory, session, redirect, send_file
import psycopg2
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase.pdfmetrics import registerFontFamily
import os
from datetime import date
import random
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet
from io import BytesIO 
from reportlab.lib.styles import ParagraphStyle



app = Flask(__name__)
app.secret_key = os.urandom(24).hex()  


font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
pdfmetrics.registerFont(TTFont('Arial', font_path))
def query_db(query, params=None, columns=None):
    try:
        with psycopg2.connect(
            dbname=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASS"),
            host=os.getenv("DB_HOST"),
            port="5432"
        ) as conn:
            with conn.cursor() as cursor:
                cursor.execute(query, params or ())
                data = cursor.fetchall()
                if columns:
                    return [dict(zip(columns, row)) for row in data]
                return data
    except psycopg2.Error as e:
        print(f"Database error: {e}")
        return {"error": "Database query failed"}



@app.route('/styles.css')
def serve_css():
    return send_from_directory('.', 'styles.css')

@app.route('/stylesLog.css')
def serveLog_css():
    return send_from_directory('.', 'stylesLog.css')


@app.route('/script.js')
def serve_js():
    return send_from_directory('.', 'script.js')


@app.route('/img/<path:filename>')
def serve_img(filename):
    return send_from_directory('img', filename)


# Универсальный маршрут для получения данных
@app.route('/get-data/<string:data_type>', methods=['GET'])
def get_data_by_type(data_type):
    queries = {
        "client": ("SELECT numberphone_client, snp_client, passport_client, id_client, login_client, password_client FROM client", ["Number", "SNP", "Passport", "id", "login_client", "password_client"]),
        "model": ("SELECT id_model, name_model, yearstart_model, yearend_model, bodyno_model FROM model", ["id_model", "name_model", "yearstart_model", "yearend_model", "bodyno_model"]),
        "manager": ("SELECT id_manager, snp_manager, start_date, login_manager, password_manager FROM manager", ["id_manager", "snp_manager", "start_date", "login_manager", "password_manager"]),
        "part": ("SELECT name_part, id_part, color_part, type_part, cost_part FROM part", ["name_part", "id_part", "color_part", "type_part", "cost_part"]),
        "supplier": ("SELECT id_supplier, name_supplier FROM supplier", ["id_supplier", "name_supplier"]),
        "config": ("""
            SELECT vin, configuration.id_model, name_config, model.name_model, model.id_model
            FROM configuration
            JOIN model ON configuration.id_model = model.id_model;
        """, ["VIN", "id_con", "name_con", "model_name", "model_id"]),
        "ordering": ("""
            SELECT 
                ordering.id_ordering, ordering.id_manager, ordering.id_client, ordering.date_ordering, 
                ordering.datepay_ordering, ordering.status_ordering, manager.snp_manager, client.snp_client
            FROM ordering
            JOIN client ON ordering.id_client = client.id_client
            LEFT JOIN manager ON ordering.id_manager = manager.id_manager;
        """, ["id_ordering", "id_manager", "id_client", "date_ordering", "date_pay_ordering", "status_ordering", "snp_manager", "snp_client"]),
        "relate": ("""
            SELECT vin, relate.id_part, part.id_part, name_part, color_part
            FROM part, relate
            WHERE part.id_part = relate.id_part;
        """, ["vin", "rid_part", "pid_part", "name_part", "color_part"]),
        "request": ("""
            SELECT id_request, request.id_supplier, request.id_manager, data_registration, status_request,
                   cost_request, data_action, request.action_type, supplier.name_supplier, manager.snp_manager,
                   supplier.id_supplier, manager.id_manager
            FROM request
            JOIN supplier ON request.id_supplier = supplier.id_supplier
            LEFT JOIN manager ON request.id_manager = manager.id_manager;
        """, ["id_request", "request.id_supplier", "request.id_manager", "data_registration", "status_request",
              "cost_request", "data_action", "action_type", "name_supplier", "snp_manager", "sid_supplier", "mid_manager"]),
        "order_parts": ("""
            SELECT order_parts.id_ordering, order_parts.id_part, order_parts.id_request, supplier.id_supplier,
                   quantity_parts, snp_manager, snp_client, name_supplier, color_part, name_part,
                   ordering.id_ordering, ordering.id_manager, ordering.id_client,
                   client.id_client, manager.id_manager, request.id_request, request.id_supplier
            FROM order_parts
            JOIN ordering ON order_parts.id_ordering = ordering.id_ordering
            JOIN part ON order_parts.id_part = part.id_part
            JOIN request ON order_parts.id_request = request.id_request
            JOIN supplier ON request.id_supplier = supplier.id_supplier
            JOIN client ON ordering.id_client = client.id_client
            JOIN manager ON ordering.id_manager = manager.id_manager;
        """, ["id_ordering", "id_part", "id_request", "id_supplier", "quantity_parts", "snp_manager", "snp_client",
              "name_supplier", "color_part", "name_part", "ordering.id_ordering", "ordering.id_manager", "ordering.id_client",
              "id_client", "id_manager", "request.id_request", "request.id_supplier"])
    }
    if data_type in queries:
        query, columns = queries[data_type]
        return jsonify(query_db(query, columns=columns))
    return jsonify({"error": "Invalid data type"}), 400

@app.route('/update-row/<string:data_type>', methods=['POST'])
def update_row(data_type):
    data = request.json

    if 'date_ordering' in data and data['date_ordering'] == '':
        data['date_ordering'] = None
    if 'date_pay_ordering' in data and data['date_pay_ordering'] == '':
        data['date_pay_ordering'] = None

    update_queries = {
        "client": (
            "UPDATE client SET numberphone_client = %s, snp_client = %s, passport_client = %s, login_client = %s, password_client = %s WHERE id_client = %s",
            ["Number", "SNP", "Passport", "login_client", "password_client", "id_client"]
        ),
        "model": (
            "UPDATE model SET name_model = %s, yearstart_model = %s, yearend_model = %s, bodyno_model = %s WHERE id_model = %s",
            ["name_model", "yearstart_model", "yearend_model", "bodyno_model", "id_model"]
        ),
        "manager": (
            "UPDATE manager SET snp_manager = %s, start_date = %s, login_manager = %s, password_manager = %s WHERE id_manager = %s",
            ["snp_manager", "start_date", "login_manager", "password_manager" "id_manager" ]
        ),
        "part": (
            "UPDATE part SET name_part = %s, color_part = %s, type_part = %s, cost_part = %s WHERE id_part = %s",
            ["name_part", "color_part", "type_part", "cost_part", "id_part"]
        ),
        "supplier": (
            "UPDATE supplier SET name_supplier = %s WHERE id_supplier = %s",
            ["name_supplier", "id_supplier"]
        ),
        "config": (
            "UPDATE configuration SET name_config = %s WHERE vin = %s",
            ["name_con", "VIN"]
        ),
        "ordering": (
            "UPDATE ordering SET date_ordering = %s, datepay_ordering = %s, status_ordering = %s, id_client = %s, id_manager = %s WHERE id_ordering = %s",
            ["date_ordering", "date_pay_ordering", "status_ordering","id_client", "id_manager", "id_ordering"]
        ),
        "request": (
            "UPDATE request SET data_registration = %s, status_request = %s, cost_request = %s, id_supplier = %s, id_manager = %s WHERE id_request = %s",
            ["data_registration", "status_request", "cost_request", "id_supplier", "mid_manager", "id_request"]
        ),
        "order_parts": (
            "UPDATE order_parts SET quantity_parts = %s WHERE id_ordering = %s AND id_part = %s AND id_request = %s",
            ["quantity_parts", "id_ordering", "id_part", "id_request"]
        ),
        "relate": (
            "UPDATE relate SET id_part = %s WHERE vin = %s",
            ["pid_part", "vin"]
        )
    }

    if data_type not in update_queries:
        return jsonify({"error": "Unsupported table"}), 400

    query, keys = update_queries[data_type]
    values = [data.get(k) for k in keys]

    try:
        with psycopg2.connect(
            dbname=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASS"),
            host=os.getenv("DB_HOST"),
            port="5432"
        ) as conn:
            with conn.cursor() as cursor:
                cursor.execute(query, values)
                conn.commit()
        return jsonify({"success": True})
    except Exception as e:
        print("Error updating:", e)
        return jsonify({"error": "Failed to update row"}), 500

@app.route('/get-statistics', methods=['GET'])
def get_statistics():
    stats = {}
    try:
        stats['total_clients'] = query_db("SELECT COUNT(*) FROM client")[0][0]
        stats['total_orders'] = query_db("SELECT COUNT(*) FROM ordering")[0][0]
        stats['total_parts'] = query_db("SELECT COUNT(*) FROM part")[0][0]
        stats['total_suppliers'] = query_db("SELECT COUNT(*) FROM supplier")[0][0]
        return jsonify(stats)
    except Exception as e:
        print("Error fetching statistics:", e)
        return jsonify({"error": "Failed to fetch statistics"}), 500

@app.route('/login', methods=['GET'])
def login_page():
    return send_from_directory('.', 'login.html')

@app.route('/delete-row/order_parts_cascade', methods=['POST'])
def delete_order_parts_and_related():
    data = request.json
    id_ordering = data.get('id_ordering')
    id_part = data.get('id_part')
    id_request = data.get('id_request')
    id_manager = data.get('id_manager')
    mode = data.get('mode')

    try:
        with psycopg2.connect(
            dbname=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASS"),
            host=os.getenv("DB_HOST"),
            port="5432"
        ) as conn:
            with conn.cursor() as cursor:
                if mode == 'order_parts':
                    # Удаляем строку из order_parts
                    cursor.execute("""
                        DELETE FROM order_parts 
                        WHERE id_ordering = %s AND id_part = %s AND id_request = %s
                    """, (id_ordering, id_part, id_request))

                    # Удаляем request, если больше не используется
                    cursor.execute("""
                        DELETE FROM request 
                        WHERE id_request = %s
                        AND NOT EXISTS (
                            SELECT 1 FROM order_parts WHERE id_request = %s
                        )
                    """, (id_request, id_request))

                    # Удаляем ordering, если больше не используется
                    cursor.execute("""
                        DELETE FROM ordering 
                        WHERE id_ordering = %s
                        AND NOT EXISTS (
                            SELECT 1 FROM order_parts WHERE id_ordering = %s
                        )
                    """, (id_ordering, id_ordering))

                elif mode == 'manager':
                    # Обнуляем manager в request и ordering
                    cursor.execute("""
                        UPDATE request
                        SET id_manager = NULL
                        WHERE id_manager = %s
                    """, (id_manager,))
                    cursor.execute("""
                        UPDATE ordering
                        SET id_manager = NULL
                        WHERE id_manager = %s
                    """, (id_manager,))

                    # Удаляем менеджера
                    cursor.execute("""
                        DELETE FROM manager
                        WHERE id_manager = %s
                    """, (id_manager,))

                elif mode == 'client':
                    id_client = data.get('id_client')

                    # Получим все id_ordering клиента
                    cursor.execute("SELECT id_ordering FROM ordering WHERE id_client = %s", (id_client,))
                    orderings = cursor.fetchall()
                    id_ordering_list = [row[0] for row in orderings]

                    if id_ordering_list:
                        # Удалим связанные строки из order_parts
                        cursor.execute("""
                            DELETE FROM order_parts 
                            WHERE id_ordering = ANY(%s)
                        """, (id_ordering_list,))

                        # Удалим сами заказы
                        cursor.execute("""
                            DELETE FROM ordering 
                            WHERE id_client = %s
                        """, (id_client,))

                    # Удалим клиента
                    cursor.execute("""
                        DELETE FROM client 
                        WHERE id_client = %s
                    """, (id_client,))

                elif mode == 'config':
                    vin = data.get('VIN')

                    # Удаляем строку из relate по VIN
                    cursor.execute("""
                        DELETE FROM relate
                        WHERE vin = %s
                    """, (vin,))

                    # Удаляем строку из configuration по VIN
                    cursor.execute("""
                        DELETE FROM configuration
                        WHERE vin = %s
                    """, (vin,))
                
                elif mode == 'model':
                    id_model = data.get('id_model')

                    # 1. Получим все VIN, связанные с этой моделью
                    cursor.execute("SELECT vin FROM configuration WHERE id_model = %s", (id_model,))
                    vin_list = [row[0] for row in cursor.fetchall()]

                    if vin_list:
                        # 2. Удалим из relate по VIN
                        cursor.execute("""
                            DELETE FROM relate
                            WHERE vin = ANY(%s)
                        """, (vin_list,))

                    # 3. Удалим конфигурации
                    cursor.execute("""
                        DELETE FROM configuration
                        WHERE id_model = %s
                    """, (id_model,))

                    # 4. Удалим саму модель
                    cursor.execute("""
                        DELETE FROM model
                        WHERE id_model = %s
                    """, (id_model,))

                elif mode == 'ordering':
                    id_ordering = data.get('id_ordering')

                    # 1. Удалим все order_parts, связанные с заказом
                    cursor.execute("""
                        DELETE FROM order_parts 
                        WHERE id_ordering = %s
                    """, (id_ordering,))

                    # 2. Удалим сам заказ
                    cursor.execute("""
                        DELETE FROM ordering 
                        WHERE id_ordering = %s
                    """, (id_ordering,))
                
                elif mode == 'part':
                    id_part = data.get('id_part')

                    # Найдём все id_ordering, где используется эта деталь
                    cursor.execute("""
                        SELECT DISTINCT id_ordering 
                        FROM order_parts 
                        WHERE id_part = %s
                    """, (id_part,))
                    id_ordering_list = [row[0] for row in cursor.fetchall()]

                    # Удалим строки из order_parts по этой детали
                    cursor.execute("""
                        DELETE FROM order_parts 
                        WHERE id_part = %s
                    """, (id_part,))

                    # Удалим заказы, если они были найдены
                    if id_ordering_list:
                        cursor.execute("""
                            DELETE FROM ordering 
                            WHERE id_ordering = ANY(%s)
                        """, (id_ordering_list,))

                    # Удалим саму деталь
                    cursor.execute("""
                        DELETE FROM part 
                        WHERE id_part = %s
                    """, (id_part,))

                elif mode == 'request':
                    id_request = data.get('id_request')

                    # Удаляем order_parts, связанные с этой заявкой
                    cursor.execute("""
                        DELETE FROM order_parts 
                        WHERE id_request = %s
                    """, (id_request,))

                    # Удаляем саму заявку
                    cursor.execute("""
                        DELETE FROM request 
                        WHERE id_request = %s
                    """, (id_request,))

                elif mode == 'supplier':
                    id_supplier = data.get('id_supplier')

                    # 1. Получим все id_request от этого поставщика
                    cursor.execute("""
                        SELECT id_request 
                        FROM request 
                        WHERE id_supplier = %s
                    """, (id_supplier,))
                    id_request_list = [row[0] for row in cursor.fetchall()]

                    # 2. Удалим связанные order_parts
                    if id_request_list:
                        cursor.execute("""
                            DELETE FROM order_parts 
                            WHERE id_request = ANY(%s)
                        """, (id_request_list,))

                    # 3. Удалим заявки
                    cursor.execute("""
                        DELETE FROM request 
                        WHERE id_supplier = %s
                    """, (id_supplier,))

                    # 4. Удалим поставщика
                    cursor.execute("""
                        DELETE FROM supplier 
                        WHERE id_supplier = %s
                    """, (id_supplier,))

   

                else:
                    return jsonify({"error": "Invalid mode"}), 400

                conn.commit()
        return jsonify({"success": True})
    except Exception as e:
        print("Ошибка при каскадном удалении:", e)
        return jsonify({"error": "Ошибка при удалении"}), 500


@app.route('/create-order', methods=['POST'])
def create_order():
    data = request.json
    items = data.get('items', [])
    id_client = data.get('id_client')  # только если оформляет менеджер

    if not items or not isinstance(items, list):
        return jsonify({'error': 'Неверный список товаров'}), 400

    try:
        with psycopg2.connect(
            dbname=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASS"),
            host=os.getenv("DB_HOST"),
            port="5432"
        ) as conn:
            with conn.cursor() as cursor:
                # 1. Получить случайного поставщика
                cursor.execute("SELECT id_supplier FROM supplier")
                suppliers = [row[0] for row in cursor.fetchall()]
                if not suppliers:
                    return jsonify({'error': 'Нет поставщиков'}), 400
                id_supplier = random.choice(suppliers)

                # 2. Определить id_manager и id_client
                user_type = session.get('user_type')
                id_manager = session.get('user_id') if user_type == 'manager' else None
                if user_type == 'client':
                    id_client = session.get('user_id')
                elif user_type == 'manager' and not id_client:
                    return jsonify({'error': 'Менеджер должен указать id клиента'}), 400

                today = date.today()

                # 3. Посчитать стоимость заявки
                part_ids = tuple(item['id_part'] for item in items)
                cursor.execute("SELECT id_part, cost_part FROM part WHERE id_part IN %s", (part_ids,))
                cost_map = {row[0]: row[1] for row in cursor.fetchall()}

                total_cost = sum(
                    cost_map[item['id_part']] * item['quantity']
                    for item in items if item['id_part'] in cost_map
                )

                # 4. Создать заявку
                cursor.execute("""
                    INSERT INTO request (id_supplier, id_manager, data_registration, status_request, cost_request)
                    VALUES (%s, %s, %s, %s, %s)
                    RETURNING id_request
                """, (id_supplier, id_manager, today, 1, total_cost))
                id_request = cursor.fetchone()[0]

                # 5. Создать заказ
                cursor.execute("""
                    INSERT INTO ordering (id_manager, id_client, date_ordering, datepay_ordering, status_ordering)
                    VALUES (%s, %s, %s, %s, %s)
                    RETURNING id_ordering
                """, (id_manager, id_client, today, None, 1))
                id_ordering = cursor.fetchone()[0]

                # Проверим, что id_ordering и id_request существуют
                cursor.execute("SELECT 1 FROM ordering WHERE id_ordering = %s", (id_ordering,))
                if cursor.fetchone() is None:
                    return jsonify({'error': 'id_ordering не найден'}), 400

                cursor.execute("SELECT 1 FROM request WHERE id_request = %s", (id_request,))
                if cursor.fetchone() is None:
                    return jsonify({'error': 'id_request не найден'}), 400

                # Добавление записей в order_parts
                for item in items:
                    cursor.execute("""
                        INSERT INTO order_parts (id_ordering, id_part, id_request, quantity_parts)
                        VALUES (%s, %s, %s, %s)
                    """, (id_ordering, item['id_part'], id_request, item['quantity']))


                conn.commit()
                return jsonify({
                    'success': True,
                    'id_request': id_request,
                    'id_ordering': id_ordering
                })

    except Exception as e:
        print("Ошибка при создании заказа:", e)
        return jsonify({'error': 'Ошибка на сервере'}), 500


@app.route('/get-my-orders')
def get_my_orders():
    user_type = session.get('user_type')
    user_id = session.get('user_id')

    try:
        with psycopg2.connect(
            dbname=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASS"),
            host=os.getenv("DB_HOST"),
            port="5432"
        ) as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT 
                        p.name_part, p.cost_part,
                        s.name_supplier,
                        op.quantity_parts,
                        o.date_ordering, o.datepay_ordering, o.status_ordering, o.id_ordering
                    FROM ordering o
                    JOIN order_parts op ON o.id_ordering = op.id_ordering
                    JOIN request r ON op.id_request = r.id_request
                    JOIN supplier s ON r.id_supplier = s.id_supplier
                    JOIN part p ON op.id_part = p.id_part
                    WHERE o.id_client = %s
                    ORDER BY o.date_ordering DESC
                """, (user_id,))
                rows = cursor.fetchall()

                result = []
                for row in rows:
                    result.append({
                        'name_part': row[0],
                        'cost_part': row[1],
                        'name_supplier': row[2],
                        'quantity_parts': row[3],
                        'date_ordering': row[4],
                        'datepay_ordering': row[5],
                        'status_ordering': row[6],
                        'id_ordering': row[7]
                    })

                return jsonify(result)

    except Exception as e:
        print("Ошибка получения заказов клиента:", e)
        return jsonify({'error': 'Ошибка сервера'}), 500

@app.route('/get-report')
def get_report():
    report_type = request.args.get('type')

    try:
        with psycopg2.connect(
            dbname=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASS"),
            host=os.getenv("DB_HOST"),
            port="5432"
        ) as conn:
            with conn.cursor() as cursor:
                if report_type == 'manager_sales':
                    cursor.execute("""
                        SELECT m.snp_manager AS "Менеджер",
                               COUNT(o.id_ordering) AS "Кол-во заказов",
                               COALESCE(SUM(r.cost_request), 0) AS "Сумма продаж"
                        FROM manager m
                        LEFT JOIN ordering o ON o.id_manager = m.id_manager
                        LEFT JOIN request r ON EXISTS (
                            SELECT 1 FROM order_parts op WHERE op.id_ordering = o.id_ordering AND op.id_request = r.id_request
                        )
                        GROUP BY m.snp_manager
                        ORDER BY "Сумма продаж" DESC
                    """)

                elif report_type == 'popular_parts':
                    cursor.execute("""
                        SELECT p.name_part AS "Деталь",
                               SUM(op.quantity_parts) AS "Продано (шт)",
                               SUM(op.quantity_parts * p.cost_part) AS "Общая сумма"
                        FROM order_parts op
                        JOIN part p ON p.id_part = op.id_part
                        GROUP BY p.name_part
                        ORDER BY "Продано (шт)" DESC
                    """)

                elif report_type == 'client_orders':
                    cursor.execute("""
                        SELECT c.snp_client AS "Клиент",
                               COUNT(o.id_ordering) AS "Кол-во заказов",
                               COALESCE(SUM(r.cost_request), 0) AS "Сумма покупок"
                        FROM client c
                        LEFT JOIN ordering o ON o.id_client = c.id_client
                        LEFT JOIN request r ON EXISTS (
                            SELECT 1 FROM order_parts op WHERE op.id_ordering = o.id_ordering AND op.id_request = r.id_request
                        )
                        GROUP BY c.snp_client
                        ORDER BY "Сумма покупок" DESC
                    """)

                else:
                    return jsonify([])

                columns = [desc[0] for desc in cursor.description]
                rows = cursor.fetchall()

                data = [dict(zip(columns, row)) for row in rows]
                return jsonify(data)

    except Exception as e:
        print("Ошибка при получении отчёта:", e)
        return jsonify([])

@app.route('/')
def serve_front():
    with open('front.html', 'r', encoding='utf-8') as f:
        return Response(f.read(), content_type='text/html; charset=utf-8')
    
@app.route("/get-report-pdf")
def get_report_pdf():
    report_type = request.args.get('type')

    try:
        pdfmetrics.registerFont(TTFont('RobotoItalic', 'Roboto-Italic-VariableFont_wdth,wght.ttf'))  # или старое имя, если не переименуешь
        registerFontFamily('RobotoItalic', normal='RobotoItalic', bold='RobotoItalic', italic='RobotoItalic', boldItalic='RobotoItalic')
    except Exception as e:
        print("Ошибка при подключении шрифта:", e)

    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4)
    styles = getSampleStyleSheet()
    styles.add(ParagraphStyle(name='Cyrillic', fontName='RobotoItalic', fontSize=12))


    elements = []
    elements.append(Paragraph(f"Отчёт: {report_type}", styles['Cyrillic']))
    elements.append(Spacer(1, 12))

    try:
        with psycopg2.connect(
            dbname=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASS"),
            host=os.getenv("DB_HOST"),
            port="5432"
        ) as conn:
            with conn.cursor() as cursor:

                if report_type == 'manager_sales':
                    cursor.execute("""
                        SELECT m.snp_manager AS "Менеджер",
                               COUNT(o.id_ordering) AS "Кол-во заказов",
                               COALESCE(SUM(r.cost_request), 0) AS "Сумма продаж"
                        FROM manager m
                        LEFT JOIN ordering o ON o.id_manager = m.id_manager
                        LEFT JOIN request r ON EXISTS (
                            SELECT 1 FROM order_parts op WHERE op.id_ordering = o.id_ordering AND op.id_request = r.id_request
                        )
                        GROUP BY m.snp_manager
                        ORDER BY "Сумма продаж" DESC
                    """)
                elif report_type == 'popular_parts':
                    cursor.execute("""
                        SELECT p.name_part AS "Деталь",
                               SUM(op.quantity_parts) AS "Продано (шт)",
                               SUM(op.quantity_parts * p.cost_part) AS "Общая сумма"
                        FROM order_parts op
                        JOIN part p ON p.id_part = op.id_part
                        GROUP BY p.name_part
                        ORDER BY "Продано (шт)" DESC
                    """)
                elif report_type == 'client_orders':
                    cursor.execute("""
                        SELECT c.snp_client AS "Клиент",
                               COUNT(o.id_ordering) AS "Кол-во заказов",
                               COALESCE(SUM(r.cost_request), 0) AS "Сумма покупок"
                        FROM client c
                        LEFT JOIN ordering o ON o.id_client = c.id_client
                        LEFT JOIN request r ON EXISTS (
                            SELECT 1 FROM order_parts op WHERE op.id_ordering = o.id_ordering AND op.id_request = r.id_request
                        )
                        GROUP BY c.snp_client
                        ORDER BY "Сумма покупок" DESC
                    """)
                else:
                    return jsonify({"error": "Неизвестный тип отчёта"}), 400

                columns = [desc[0] for desc in cursor.description]
                rows = cursor.fetchall()

                if not rows:
                    elements.append(Paragraph("Нет данных для отчёта.", styles['Cyrillic']))
                else:
                    data = [columns] + [list(row) for row in rows]

                    table = Table(data, hAlign='LEFT')
                    table.setStyle(TableStyle([
                        ('FONTNAME', (0, 0), (-1, -1), 'RobotoItalic'),
                        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#2264E5")),
                        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
                        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                        ('BOTTOMPADDING', (0, 0), (-1, 0), 10),
                        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
                    ]))

                    elements.append(table)

                doc.build(elements)
                buffer.seek(0)
                return send_file(buffer, as_attachment=True, download_name='report.pdf', mimetype='application/pdf')

    except Exception as e:
        print("Ошибка при генерации PDF:", e)
        return jsonify({"error": "Ошибка при генерации PDF"}), 500

@app.route('/login', methods=['POST'])
def login():
    data = request.json
    login_input = data.get("login")
    password_input = data.get("password")

    # Проверка клиента
    client = query_db(
        "SELECT id_client, snp_client FROM client WHERE login_client = %s AND password_client = %s",
        (login_input, password_input)
    )

    if client:
        client_id, snp_client = client[0]
        session['user_type'] = 'client'
        session['user_id'] = client_id
        session['user_name'] = snp_client.split()[1] if snp_client else "Client"
        return jsonify({"success": True, "role": "client", "userName": session['user_name']})


    manager = query_db(
        "SELECT id_manager, snp_manager, role FROM manager WHERE login_manager = %s AND password_manager = %s",
        (login_input, password_input)
    )

    if manager:
        manager_id, snp_manager, role = manager[0]
        session['user_type'] = 'manager'
        session['user_id'] = manager_id
        session['user_name'] = snp_manager.split()[1] if snp_manager else "Manager"
        session['user_role'] = role
        return jsonify({"success": True, "role": role, "userName": session['user_name']})

    return jsonify({"success": False})

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()

    required_fields = ['snp', 'phone', 'passport', 'login', 'password']
    if not all(data.get(field) for field in required_fields):
        return jsonify({'success': False, 'error': 'Missing fields'}), 400

    try:
        with psycopg2.connect(
            dbname=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASS"),
            host=os.getenv("DB_HOST"),
            port="5432"
        ) as conn:
            with conn.cursor() as cursor:
                # Проверка логина во всех таблицах
                cursor.execute("""
                    SELECT 1 FROM client WHERE login_client = %s
                    UNION
                    SELECT 1 FROM manager WHERE login_manager = %s
                    UNION
                    SELECT 1 FROM supplier WHERE login_supplier = %s
                """, (data['login'], data['login'], data['login']))
                
                if cursor.fetchone():
                    return jsonify({'success': False, 'error': 'Login already exists'}), 409

                # Вставка нового клиента
                cursor.execute("""
                    INSERT INTO client (snp_client, numberphone_client, passport_client, login_client, password_client)
                    VALUES (%s, %s, %s, %s, %s)
                """, (data['snp'], data['phone'], data['passport'], data['login'], data['password']))

                conn.commit()
                return jsonify({'success': True})
    except Exception as e:
        print("Registration error:", e)
        return jsonify({'success': False, 'error': 'Server error'}), 500

@app.route('/register', methods=['GET'])
def serve_register():
    return send_from_directory('.', 'register.html')

@app.route('/add-row/<string:entity>', methods=['POST'])
def add_row(entity):
    data = request.get_json()

    insert_queries = {
        "supplier": (
            """
            INSERT INTO supplier (name_supplier, login_supplier, password_supplier)
            VALUES (%s, %s, %s)
            """,
            ["name_supplier", "login_supplier", "password_supplier"]
        ),
        "manager": (
            """
            INSERT INTO manager (snp_manager, start_date, login_manager, password_manager, role)
            VALUES (%s, %s, %s, %s, %s)
            """,
            ["snp_manager", "start_date", "login_manager", "password_manager", "role"]
        ),
        "client": (
            """
            INSERT INTO client (snp_client, numberphone_client, passport_client, login_client, password_client)
            VALUES (%s, %s, %s, %s, %s)
            """,
            ["SNP", "Number", "Passport", "login_client", "password_client"]
        ),
        "model": (
            """
            INSERT INTO model (name_model, yearstart_model, yearend_model, bodyno_model)
            VALUES (%s, %s, %s, %s)
            """,
            ["name_model", "yearstart_model", "yearend_model", "bodyno_model"]
        ),
        "config": (
            """
            INSERT INTO configuration (vin, name_config, id_model)
            VALUES (%s, %s, %s)
            """,
            ["VIN", "name_con", "id_model"]
        ),
        "part": (
            """
            INSERT INTO part (name_part, color_part, type_part, cost_part)
            VALUES (%s, %s, %s, %s)
            """,
            ["name_part", "color_part", "type_part", "cost_part"]
        ),
        "relate": (
            """
            INSERT INTO relate (vin, id_part)
            VALUES (%s, %s)
            """,
            ["vin", "id_part"]
        )

    }

    if entity not in insert_queries:
        return jsonify({'success': False, 'error': 'Unsupported entity'}), 400

    query, keys = insert_queries[entity]
    values = [data.get(k) for k in keys]

    if not all(values):
        return jsonify({'success': False, 'error': 'All fields are required'}), 400

    try:
        with psycopg2.connect(
            dbname=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASS"),
            host=os.getenv("DB_HOST"),
            port="5432"
        ) as conn:
            with conn.cursor() as cursor:
                # Проверка логина
                login = next((v for k, v in data.items() if 'login' in k), None)
                if login:
                    cursor.execute("""
                        SELECT 1 FROM client WHERE login_client = %s
                        UNION
                        SELECT 1 FROM manager WHERE login_manager = %s
                        UNION
                        SELECT 1 FROM supplier WHERE login_supplier = %s
                    """, (login, login, login))
                    if cursor.fetchone():
                        return jsonify({'success': False, 'error': 'Login already in use'}), 409

                cursor.execute(query, values)
                conn.commit()
                return jsonify({'success': True})
    except Exception as e:
        print("Add row error:", e)
        return jsonify({'success': False, 'error': 'Server error'}), 500
    

@app.route('/get-client-orders-by-phone')
def get_client_orders_by_phone():
    user_type = session.get('user_type')
    phone = request.args.get('phone', '').strip()
    if not phone:
        return jsonify({'error': 'Номер не указан'}), 400

    try:
        with psycopg2.connect(
            dbname=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASS"),
            host=os.getenv("DB_HOST"),
            port="5432"
        ) as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT id_client FROM client WHERE numberphone_client = %s
                """, (phone,))
                result = cursor.fetchone()

                if not result:
                    return jsonify([])

                id_client = result[0]

                cursor.execute("""
                    SELECT 
                        p.name_part, p.cost_part,
                        s.name_supplier,
                        op.quantity_parts,
                        o.date_ordering, o.datepay_ordering, o.status_ordering, o.id_ordering,
                        c.snp_client, c.numberphone_client
                    FROM ordering o
                    JOIN order_parts op ON o.id_ordering = op.id_ordering
                    JOIN request r ON op.id_request = r.id_request
                    JOIN supplier s ON r.id_supplier = s.id_supplier
                    JOIN part p ON op.id_part = p.id_part
                    JOIN client c ON o.id_client = c.id_client
                    WHERE o.id_client = %s
                    ORDER BY o.date_ordering DESC
                """, (id_client,))

                rows = cursor.fetchall()
                return jsonify([
                    {
                        'name_part': row[0],
                        'cost_part': row[1],
                        'name_supplier': row[2],
                        'quantity_parts': row[3],
                        'date_ordering': row[4],
                        'datepay_ordering': row[5],
                        'status_ordering': row[6],
                        'id_ordering': row[7],
                        'snp_client': row[8],
                        'numberphone_client': row[9]
                    } for row in rows
                ])

    except Exception as e:
        print("Ошибка при получении заказов клиента менеджером:", e)
        return jsonify({'error': 'Ошибка сервера'}), 500


@app.route('/')
def index():
    if 'user_id' not in session:
        return redirect('/login')

    with open('front.html', 'r') as file:
        html = file.read()

    html += f"""
    <script>
        localStorage.setItem("clientName", "{session.get('user_name', '')}");
        localStorage.setItem("userType", "{session.get('user_type', '')}");
        localStorage.setItem("userRole", "{session.get('user_role', '')}");
        localStorage.setItem("userType", "{session.get('user_type', '')}");
        
    </script>
    """
    return Response(html, mimetype='text/html')

@app.route('/cancel-order', methods=['POST'])
def cancel_order():
    data = request.json
    id_ordering = data.get('id_ordering')

    if not id_ordering:
        return jsonify({'error': 'Не указан id заказа'}), 400

    try:
        with psycopg2.connect(
            dbname=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASS"),
            host=os.getenv("DB_HOST"),
            port="5432"
        ) as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    UPDATE ordering SET status_ordering = 7
                    WHERE id_ordering = %s
                """, (id_ordering,))
                conn.commit()
        return jsonify({'success': True})
    except Exception as e:
        print("Ошибка при отмене заказа:", e)
        return jsonify({'error': 'Ошибка сервера'}), 500



@app.route('/logout')
def logout():
    session.clear()
    return redirect('/login')


if __name__ == '__main__':
    app.run(debug=True)
