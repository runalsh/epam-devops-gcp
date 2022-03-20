FROM python:3.7
ENV PYTHONDONTWRITEBYTECODE=1
WORKDIR /app
COPY . /app
RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt
EXPOSE 8080
CMD ["python3", "app.py"]
