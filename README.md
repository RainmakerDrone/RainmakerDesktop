# RainmakerDesktop
Twitch plays cash-dropping drone

Rainmaker is a TreeHacks hack that deploys a Parrot AR Drone and flies it based on text message votes for its direction. A claw with a dollar is attached to the drone, with a timer set to let go of the dollar. It uses Twilio, Heroku and Ruby on Rails on the server side, Processing on the Desktop and Arduino on the claw and timer side. The Rainmaker team could see a similar technology being deployed to all manner of large and dense events, such as sports games, concerts, festivals, assemblies, parades, and parties.

Rainmaker desktop is a processing sketch that communicates with a Parrot AR Drone after reading JSON input from an online API. To accomplish this, simultaneous wireless and ethernet internet connections are required, since communications with the drone utilize wifi and the API requires an internet connection. The sketch utilizes [the ARDroneForP5 library](https://github.com/shigeodayo/ARDroneForP5).

It also includes operator override, whereby the computer running the application can move the drone even in the midst of it using the API Vote counts.
