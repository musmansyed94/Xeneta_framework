DROP TABLE IF EXISTS sailing_level_raw CASCADE;

CREATE TABLE sailing_level_raw (
  origin                                   text NOT NULL,
  destination                              text NOT NULL,
  origin_port_code                         text NOT NULL,
  destination_port_code                    text NOT NULL,
  service_version_and_roundtrip_identifiers text NOT NULL,
  origin_service_version_and_master         text NOT NULL,
  destination_service_version_and_master    text NOT NULL,
  origin_at_utc                             timestamptz NOT NULL,
  offered_capacity_teu                      integer NOT NULL
);

CREATE INDEX ON sailing_level_raw (origin, destination);
CREATE INDEX ON sailing_level_raw (origin_at_utc);
CREATE INDEX ON sailing_level_raw (
  service_version_and_roundtrip_identifiers,
  origin_service_version_and_master,
  destination_service_version_and_master,
  origin_at_utc
);
