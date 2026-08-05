# Compact city masterplan

Status: compact layout implemented in live `scenes/world/city/city.tscn` (Block 6). Technical top-down SVG/PNG + capture route ready; windowed FPS visual review pending. Binding polish is a follow-up block.

## Design goal

Convert the current east-west corridor into one compact neighborhood with a recognizable central node, two short loops and progression gates that reveal side routes. Preserve every existing POI and the exclusive home/city travel model.

## Zones

### 1. Residential east pocket
- Player home facade, quiet court and home return spawn.
- Short sightline to Cafe Two Hearts and the commercial street.
- Furniture/greenery masks the east map edge.

### 2. Commercial L-street
- Cafe, flower, jewelry, gift, clothing and homeware facades.
- Two perpendicular short street segments instead of one row.
- Shop windows and props create identity; entrances face the walkable route.

### 3. Central pocket
- Small paved widening, existing benches, restrained fountain/planter landmark and directional signs.
- Composition element only, not a new POI.
- Connects residential/commercial, park path and agency/service lane.

### 4. Park loop
- Curved path from the central pocket through picnic, pond/duck feeding, park benches and park restaurant.
- Returns to the leisure strip through a second short path.
- ParkGate opens a side passage from the existing city, not another straight extension.

### 5. Leisure edge
- Gym, bookstore, cinema and arcade around a compact shared forecourt.
- Karaoke/bar vignette sits at the active evening edge without blocking circulation.
- Leisure forecourt reconnects to the central pocket through the park loop.

### 6. Agency lane
- Photo studio, barber and agency facades along a narrower presentation/service street.
- AgencyGate removes construction fencing at a side lane from the central/leisure node.
- Bus stop terminates the lane and masks the west edge.

## Connections

- Primary route: Home → commercial L-street → central pocket.
- Park loop: central pocket → picnic/pond → restaurant → leisure forecourt → central pocket.
- Agency loop: central/leisure junction → agency lane → bus turnaround → leisure forecourt.
- All required POI remain within a short walk; no open-world scale.

## Sightlines and landmarks

- Home door sees the cafe sign.
- Commercial corner sees the central planter/fountain.
- Central pocket sees ParkGate greenery and cinema marquee in different directions.
- Park path reveals the restaurant canopy across the pond.
- Leisure forecourt sees the agency construction gate.
- Agency lane terminates at bus shelter/lit sign, not black void.

## Progression

- `main_street`: residential, commercial and central pocket open from start.
- `park_leisure`: ParkGate removes a fenced side path into an already visible green area.
- `agency_row`: AgencyGate removes construction fencing from a side lane near leisure.
- Gates retain existing district IDs and save state.

## Existing street activities

- Main bench: central pocket, complete parent object with sit anchor.
- Park bench: pond path.
- Duck feeding: pond edge with feeder, food anchor and duck reaction area.
- Karaoke/bar: leisure edge.
- Internet cafe/coffee: commercial side street, physically visible.
- Flower purchase: canonical flower facade; remove/confine duplicate hidden discount path.
- Bus information/candy: agency lane terminus.

## POI interaction architecture

Each movable POI/activity root owns:

- facade/props;
- static collision;
- interaction area;
- outline target;
- prompt anchor;
- player/date/animation anchors;
- audio nodes;
- used/cooldown state reference.

Moving the root must move the entire interaction structure. Existing `Interactable` and outline shader are reused.

## Lighting target

- One authoritative WorldEnvironment.
- Neutral readable ambient base.
- Warm directional key with visible shadows.
- Local warm shop windows and lamps.
- Restricted zone accents: green park, amber leisure, clean agency lighting.
- No purple wash, fully black distance or flat uniform brightness.

## Edge concealment

- Residential walls/trees east.
- Commercial building backs north/south.
- Park vegetation and terrain layering.
- Agency bus turnaround/building mass west.
- Camera/player collision prevents viewing beyond dressed edges.

## Top-down evidence requirement

After implementation create a rendered or technical top-down image showing zone boundaries, both loops, gates, entrances, street activities, player spawn and hidden edges. This document alone is not evidence of completion.
