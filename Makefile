.PHONY: up create-tunnel set-webhook delete-webhook

create-tunnel:
	lt --port 4000 &

set-webhook:
	curl -X GET https://api.telegram.org/bot$(TELEGRAM_TOKEN)/setWebhook?url=$(URL)

up: delete-webhook set-webhook
	mix phx.server

delete-webhook:
	curl -X POST -H "Content-Type: application/json" --data '{"drop_pending_updates": true}' https://api.telegram.org/bot$(TELEGRAM_TOKEN)/deleteWebhook
