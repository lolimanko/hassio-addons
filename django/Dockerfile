FROM python:3.12-slim

# 設定工作目錄
WORKDIR /media

# 複製專案環境與相關檔案
#COPY requirements.txt .
RUN python -m pip install Django
RUN python -m pip install psycopg2-binary
RUN python -m pip install gunicorn
#RUN django-admin startproject checkin13517

WORKDIR /media/checkin
#COPY . .
#RUN python -m manage.py startapp ci13517
# 啟動 Django 開發伺服器
#CMD ["python", "manage.py", "migrate" ]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
#CMD ["python", "manage.py", "startapp", "cistaff"]
#python manage.py makemigrations polls
#CMD ["python", "manage.py", "makemigrations", "ci_staff"]
#CMD ["/usr/bin/gunicorn" "checkin.wsgi:application" "--bind" "0.0.0.0:8000"]
#RUN python manage.py collectstatic
#CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:8000", "checkin.wsgi:application"]
#CMD ["python", "manage.py", "collectstatic"]
