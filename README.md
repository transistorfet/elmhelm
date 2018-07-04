 
ElmHelm
=======

A super simple note taking app written in Elm.  The API server is written in js
with express and uses a SQLite database for recording notes.  There is currently
no authentication, as this is just a toy app to learn elm.

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


