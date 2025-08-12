Here is the k6 load testing script for the 'SalesMaster & TeamHub' application, saved as `scripts/load-test.js`.

This script simulates user behavior by:
- Creating reminders via a REST API.
- Establishing a GraphQL subscription to receive real-time notifications.
- Connecting to a Socket.io channel for real-time messaging.

It includes checks for response verification, custom metrics, and placeholders for environment variables.

To run this script:
1.  Save the content below into a file named `scripts/load-test.js`.
2.  Install k6: `brew install k6` (macOS) or follow instructions on k6.io.
3.  Execute from your terminal, providing the `BASE_URL` and `AUTH_TOKEN`:
    `k6 run -e BASE_URL=http://localhost:3000 -e AUTH_TOKEN=your_jwt_token scripts/load-test.js`
    (Replace `http://localhost:3000` with your application's base URL and `your_jwt_token` with a valid JWT.)

```javascript
// scripts/load-test.js

import http from 'k6/http';
import ws from 'k6/ws';
import { check, sleep } from 'k6';
import { Counter } from 'k6/metrics';
import { uuidv4 } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js'; // For generating unique IDs

// --- Custom Metrics ---
// These custom counters help track specific actions and events during the test.
const remindersCreated = new Counter('reminders_created');
const graphqlNotificationsReceived = new Counter('graphql_notifications_received');
const socketIoMessagesSent = new Counter('socketio_messages_sent');
const socketIoMessagesReceived = new Counter('socketio_messages_received');

// --- k6 Test Options ---
// Defines the overall behavior of the load test.
export let options = {
  // Stages define the ramp-up, steady-state, and ramp-down phases of the test.
  // This example ramps up to 10 VUs, holds for 3 minutes, then ramps down.
  stages: [
    { duration: '1m', target: 10 },  // Ramp up to 10 Virtual Users (VUs) over 1 minute
    { duration: '3m', target: 10 },  // Stay at 10 VUs for 3 minutes
    { duration: '1m', target: 0 },   // Ramp down to 0 VUs over 1 minute
  ],
  // Thresholds define acceptable performance levels. If these are breached, the test will fail.
  thresholds: {
    'http_req_duration': ['p(95)<500'], // 95% of HTTP requests should complete within 500ms
    'http_req_failed': ['rate<0.01'],   // Less than 1% of HTTP requests should fail
    'ws_connecting_duration': ['p(95)<1000'], // 95% of WebSocket connections should establish within 1 second
    'reminders_created': ['count>=10'], // Ensure at least 10 reminders are created across the test
    'graphql_notifications_received': ['count>=1'], // Ensure at least one GraphQL notification is received (per VU if possible)
  },
  // Environment variables can be passed to the script using `-e` flag when running k6.
  // Example: k6 run -e BASE_URL=http://localhost:3000 -e AUTH_TOKEN=your_jwt_token scripts/load-test.js
};

// --- Main Test Function ---
// This function is executed by each Virtual User (VU) for the duration of the test.
export default function () {
  // --- Configuration ---
  // Base URL for the application, defaults to localhost if not provided via environment variable.
  const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
  // Authentication token, replace 'your_default_jwt_token' with a valid JWT for testing.
  const AUTH_TOKEN = __ENV.AUTH_TOKEN || 'your_default_jwt_token';
  // Standard headers for authenticated HTTP requests.
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${AUTH_TOKEN}`,
  };

  // Generate a unique user ID for the current VU and iteration.
  // This helps simulate distinct users and allows for user-specific subscriptions.
  const userId = `user_${__VU}_${__ITER}`;

  // --- Scenario 1: REST API - Create Reminder ---
  // Simulates a user creating a new reminder via the REST API.
  console.log(`VU ${__VU}: Creating a reminder...`);
  const reminderPayload = {
    userId: userId,
    title: `Team Meeting Reminder - VU ${__VU} Iter ${__ITER}`,
    category: 'Meeting',
    date: new Date().toISOString().split('T')[0], // Current date in YYYY-MM-DD format
    recurrence: 'weekly',
  };

  const createReminderRes = http.post(
    `${BASE_URL}/api/v1/reminders`,
    JSON.stringify(reminderPayload),
    { headers: headers, tags: { name: 'REST_CreateReminder' } } // Add tags for better metric filtering
  );

  // Checks to verify the success of the reminder creation.
  check(createReminderRes, {
    'REST: Reminder created successfully (status 201)': (r) => r.status === 201,
    'REST: Response body contains id': (r) => r.json() && r.json().id !== undefined,
  });

  if (createReminderRes.status === 201) {
    remindersCreated.add(1); // Increment custom counter on success
    console.log(`VU ${__VU}: Reminder created with ID: ${createReminderRes.json().id}`);
  } else {
    console.error(`VU ${__VU}: Failed to create reminder. Status: ${createReminderRes.status}, Body: ${createReminderRes.body}`);
  }

  sleep(2); // Pause for 2 seconds to simulate user think time

  // --- Scenario 2: GraphQL Subscription for Real-time Notifications ---
  // Simulates a user subscribing to real-time notifications via GraphQL over WebSockets.
  console.log(`VU ${__VU}: Connecting to GraphQL WebSocket for notifications...`);
  // Convert HTTP base URL to WebSocket URL (e.g., http:// -> ws://)
  const graphqlWsUrl = BASE_URL.replace('http', 'ws') + '/graphql';

  let graphqlConnected = false; // Flag to track WebSocket connection status

  // Establish WebSocket connection for GraphQL.
  ws.connect(graphqlWsUrl, { tags: { name: 'GraphQL_Subscription' } }, function (socket) {
    // Event handler for successful WebSocket connection.
    socket.on('open', () => {
      console.log(`VU ${__VU}: GraphQL WebSocket connected.`);
      graphqlConnected = true;

      // GraphQL over WebSocket Protocol: Send 'connection_init' message.
      // This is the first message to establish the GraphQL connection.
      socket.send(JSON.stringify({
        type: 'connection_init',
        payload: {}, // Authentication token might be passed here depending on GraphQL server setup.
      }));

      // GraphQL over WebSocket Protocol: Send 'start' message for the subscription.
      // The 'onNotification' subscription is defined here with a dynamic userId.
      const subscriptionId = uuidv4(); // Unique ID for this specific subscription operation
      socket.send(JSON.stringify({
        type: 'start',
        id: subscriptionId,
        payload: {
          query: `
            subscription onNotification($userId: ID!) {
              onNotification(userId: $userId) {
                id
                message
                type
              }
            }
          `,
          variables: { userId: userId }, // Pass the VU's unique userId to the subscription
        },
      }));
      console.log(`VU ${__VU}: Sent GraphQL subscription request for userId: ${userId}`);
    });

    // Event handler for incoming WebSocket messages.
    socket.on('message', (data) => {
      const msg = JSON.parse(data);
      // Check if the message is a 'data' type containing a notification.
      if (msg.type === 'data' && msg.payload && msg.payload.data && msg.payload.data.onNotification) {
        graphqlNotificationsReceived.add(1); // Increment custom counter
        console.log(`VU ${__VU}: Received GraphQL Notification: ${JSON.stringify(msg.payload.data.onNotification)}`);
      } else if (msg.type === 'connection_ack') {
        console.log(`VU ${__VU}: GraphQL Connection Acknowledged.`);
      } else if (msg.type === 'ka') {
        // 'ka' (keep-alive) messages are common in GraphQL subscriptions; ignore them.
      } else if (msg.type === 'error') {
        console.error(`VU ${__VU}: GraphQL WS Error: ${JSON.stringify(msg)}`);
      }
    });

    // Event handler for WebSocket connection closure.
    socket.on('close', () => {
      console.log(`VU ${__VU}: GraphQL WebSocket closed.`);
      graphqlConnected = false;
    });

    // Event handler for WebSocket errors.
    socket.on('error', (e) => {
      if (e.error()) {
        console.error(`VU ${__VU}: GraphQL WebSocket Error: ${e.error()}`);
      }
    });

    // Keep the WebSocket connection open for a specific duration to allow receiving notifications.
    // In a real-world scenario, this duration might be longer or tied to the VU's overall session.
    socket.setTimeout(function () {
      console.log(`VU ${__VU}: Closing GraphQL WebSocket after 10 seconds.`);
      socket.close();
    }, 10000); // Keep open for 10 seconds
  });

  // Check if the GraphQL WebSocket connection was successfully established.
  check(graphqlConnected, { 'GraphQL WS: Successfully connected': (connected) => connected === true });
  sleep(2); // Pause for 2 seconds

  // --- Scenario 3: Socket.io Connection for Real-time Messaging ---
  // Simulates a user connecting to a Socket.io channel.
  // Socket.io typically involves an initial HTTP polling request to get a session ID (sid),
  // followed by an upgrade to a WebSocket connection.
  console.log(`VU ${__VU}: Connecting to Socket.io...`);
  const socketIoPollingUrl = `${BASE_URL}/socket.io/?EIO=3&transport=polling`;
  let sid = ''; // Variable to store the session ID

  // Step 1: Get Socket.io session ID via HTTP polling.
  const pollingRes = http.get(socketIoPollingUrl, { tags: { name: 'SocketIO_Polling' } });
  check(pollingRes, {
    'Socket.io Polling: Status 200': (r) => r.status === 200,
    'Socket.io Polling: Contains SID': (r) => r.body.includes('"sid":"'),
  });

  if (pollingRes.status === 200 && pollingRes.body.includes('"sid":"')) {
    try {
      // Socket.io polling responses can be prefixed (e.g., '96:0').
      // We need to extract the JSON part to parse the SID.
      const bodyContent = pollingRes.body.substring(pollingRes.body.indexOf('{'));
      const parsedBody = JSON.parse(bodyContent);
      sid = parsedBody.sid;
      console.log(`VU ${__VU}: Socket.io SID obtained: ${sid}`);
    } catch (e) {
      console.error(`VU ${__VU}: Failed to parse Socket.io polling response: ${e}, Body: ${pollingRes.body}`);
    }
  } else {
    console.error(`VU ${__VU}: Failed to get Socket.io SID. Status: ${pollingRes.status}, Body: ${pollingRes.body}`);
  }

  if (sid) {
    // Step 2: Connect to Socket.io WebSocket endpoint using the obtained SID.
    const socketIoWsUrl = `${BASE_URL.replace('http', 'ws')}/socket.io/?EIO=3&transport=websocket&sid=${sid}`;
    let socketIoConnected = false;

    ws.connect(socketIoWsUrl, { tags: { name: 'SocketIO_WebSocket' } }, function (socket) {
      // Event handler for successful Socket.io WebSocket connection.
      socket.on('open', () => {
        console.log(`VU ${__VU}: Socket.io WebSocket connected.`);
        socketIoConnected = true;
        // Send Socket.io 'connect' packet (type '40').
        socket.send('40');
        socketIoMessagesSent.add(1);
      });

      // Event handler for incoming Socket.io WebSocket messages.
      socket.on('message', (data) => {
        socketIoMessagesReceived.add(1); // Increment custom counter for received messages
        if (data === '3') { // Socket.io Pong message (response to ping)
          // console.log(`VU ${__VU}: Socket.io Pong received.`);
        } else if (data.startsWith('42')) { // Socket.io Event message (e.g., '42["eventName", {data}]')
          try {
            const msg = JSON.parse(data.substring(2)); // Remove '42' prefix and parse JSON
            console.log(`VU ${__VU}: Socket.io Event received: ${JSON.stringify(msg)}`);
          } catch (e) {
            console.error(`VU ${__VU}: Failed to parse Socket.io event message: ${e}, Data: ${data}`);
          }
        }
      });

      // Event handler for Socket.io WebSocket connection closure.
      socket.on('close', () => {
        console.log(`VU ${__VU}: Socket.io WebSocket closed.`);
        socketIoConnected = false;
      });

      // Event handler for Socket.io WebSocket errors.
      socket.on('error', (e) => {
        if (e.error()) {
          console.error(`VU ${__VU}: Socket.io WebSocket Error: ${e.error()}`);
        }
      });

      // Periodically send a Socket.io 'ping' (type '2') to keep the connection alive
      // and simulate ongoing activity.
      socket.setInterval(function timeout() {
        if (socket.readyState === ws.OPEN) {
          socket.send('2'); // Socket.io Ping
          socketIoMessagesSent.add(1); // Increment counter for sent messages
          // console.log(`VU ${__VU}: Socket.io Ping sent.`);
        }
      }, 5000); // Send ping every 5 seconds

      // Keep the Socket.io WebSocket connection open for a specific duration.
      socket.setTimeout(function () {
        console.log(`VU ${__VU}: Closing Socket.io WebSocket after 15 seconds.`);
        socket.close();
      }, 15000); // Keep open for 15 seconds
    });

    // Check if the Socket.io WebSocket connection was successfully established.
    check(socketIoConnected, { 'Socket.io WS: Successfully connected': (connected) => connected === true });
  } else {
    console.error(`VU ${__VU}: Skipping Socket.io WebSocket connection due to missing SID.`);
  }

  sleep(5); // Final pause to ensure connections have time to close or for the next iteration to begin.
}
```