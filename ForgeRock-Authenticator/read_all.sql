SELECT
    i.issuer,
    i.accountName,
    i.image,
    i.imageURL,
    i.bgColor,
	m.type,
    m.version,
    m.mechanismUID,
    m.options,
    n.timeReceived,
    n.timeExpired,
    n.data,
    n.pending,
    n.approved
FROM identity i, mechanism m LEFT OUTER JOIN notification n ON m.mechanismUID = n.mechanismUID
WHERE i.issuer = m.idIssuer AND i.accountName = m.idAccountName;