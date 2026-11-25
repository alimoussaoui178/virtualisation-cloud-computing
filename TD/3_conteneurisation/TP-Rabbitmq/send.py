"""Producteur RabbitMQ : envoie un message 'Hello World!' dans la file 'hello'."""
import pika

connection = pika.BlockingConnection(pika.ConnectionParameters(host="localhost"))
channel = connection.channel()

# Crée la file si elle n'existe pas encore
channel.queue_declare(queue="hello")

channel.basic_publish(exchange="", routing_key="hello", body="Hello World!")
print(" [x] Sent 'Hello World!'")

connection.close()
