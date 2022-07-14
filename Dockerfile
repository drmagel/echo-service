FROM node:16.16.0
ENV FRUIT=echo-service
ENV WORKDIR=/opt/$FRUIT
RUN mkdir $WORKDIR
COPY src/index.js $WORKDIR
COPY src/package.json $WORKDIR
WORKDIR $WORKDIR
RUN npm install
CMD ["./index.js"]