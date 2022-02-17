 
ElmHelm
=======

###### *Started July 3, 2018*

A simple and unpolished note taking app written in Elm.  The API server is
written in JavaScript with Express.js and uses a SQLite database for recording
notes.  I also wrote an Ocaml version of the API but I'm not sure if it's
working at the moment.  There is no authentication, as this is just a toy app
to learn elm.

Running
-------

### API Server

```
cd api/
npm install
npm start
```

### Client

```
cd client/
npm install -g elm
elm-package install
elm-reactor
```


