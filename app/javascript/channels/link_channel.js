import { createConsumer } from "@rails/actioncable"

document.addEventListener('turbolinks:load', function() {
  console.debug('turbolinks:load');

  let api_url = document.getElementById('api-url');
  let consumer = createConsumer(api_url.textContent);

  consumer.subscriptions.create({
    channel: "LinkChannel",
    chat: true,
  }, {
    connected() {
      // Called when the subscription is ready for use on the server

      console.debug('Link connected');
    },

    disconnected() {
      // Called when the subscription has been terminated by the server

      console.debug('Link disconnected');
    },

    received(data) {
      // Called when there's incoming data on the websocket for this channel

      if (data.type == 'message') {
        let messages = document.getElementById('messages');
        let message = document.getElementById('message-template').cloneNode(true);
        message.id = '';
        message.style = '';

        if (data.name) {
          let tmp = message.getElementsByClassName('name')[0];
          tmp.textContent = data.name;
        }

        if (data.text) {
          let tmp = message.getElementsByClassName('message')[0];
          tmp.textContent = data.text;
        }

        if (data.timestamp) {
          let ts = parseInt(data.timestamp);
          let tmp = message.getElementsByClassName('timestamp')[0];
          tmp.textContent = (new Date(ts * 1000)).toLocaleTimeString();
        }

        messages.prepend(message);
      }
    }
  });
});
