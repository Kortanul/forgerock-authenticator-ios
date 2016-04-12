CREATE TABLE identity (
issuer         TEXT,
accountName    TEXT,
image          BLOB,
imageURL       TEXT,
bgColor        TEXT,
PRIMARY KEY( issuer,  accountName ));

CREATE TABLE  mechanism (
idIssuer        TEXT,
idAccountName   TEXT,
mechanismUID    TEXT UNIQUE,
type            TEXT,
version         INTEGER,
options         TEXT,
PRIMARY KEY ( idIssuer, idAccountName, type ),
FOREIGN KEY( idIssuer,  idAccountName )
REFERENCES  identity ( issuer,  accountName ));

CREATE TABLE  notification  (
mechanismUID    TEXT,
timeReceived    TEXT,
timeExpired     TEXT,
data            TEXT,
pending         INT,
approved        INT,
FOREIGN KEY( mechanismUID )
REFERENCES  mechanism ( mechanismUID ),
PRIMARY KEY( mechanismUID,  timeReceived ));
