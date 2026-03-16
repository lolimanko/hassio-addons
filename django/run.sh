#!/bin/ash
gunicorn checkin.wsgi:application --bind" 0.0.0.0:8000