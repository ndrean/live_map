# LiveMap

mix phx.gen.context Downwind Place places latitude:float longitude:float addre
ss:string country:string

mix phx.gen.context Downwind Event events start end date:date
cd assets && npm i leaflet leaft-control-geocder valtio

```elixir
config.esbuild
--target=es2020 #<- Valtio
--sourcemap #<- Leaflet
--loader:.png=dataurl #<- Leaflet icon
```

Leaflet -> id="map", style="height, width"
app.css
@import 'leaflet/dist/leaflet.css';
@import 'leaflet-control-geocoder/dist/Control.Geocoder.css';

router
live "/"

export GOOGLE_CLIENT_ID=427903880331-eo7ihmos753oat8qbblfomm121htqjnf.apps.googleusercontent.com
export GOOGLE_CLIENT_SECRET=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

export GITHUB_CLIENT_ID=2a152f5479f2ef7fc0d0
export GITHUB_CLIENT_SECRET=bb45d66c26b844604b6b03665f80ab8e76a781cf

`source .env`
