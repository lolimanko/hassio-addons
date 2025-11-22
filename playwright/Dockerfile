FROM python:3.11

# Set the working directory in the container
WORKDIR /app
ADD . /app

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PLAYWRIGHT_BROWSERS_PATH=/app/ms-playwright

# Install system dependencies
RUN apt-get update && apt-get install -y

# Install Playwright
RUN pip install playwright

# Install Playwright browsers and dependencies
RUN playwright install --with-deps chromium
RUN pip install APScheduler
RUN pip install requests
RUN pip install psycopg2-binary
# Command to run the Playwright test script

CMD ["python", "playwright_checkin.py"]