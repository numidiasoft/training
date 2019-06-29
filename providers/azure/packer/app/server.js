const express = require("express")
const app = express()
const port = 9000

app.get("/v1/api", (_req, res) => res.send("Hello World!"))
app.get("/", (_req, res) =>
  res.json({
    message: "The new version of the blue API is up",
    status: "OK"
  })
)

app.listen(port, "0.0.0.0", () =>
  console.log(`Example app listening on port ${port}!`)
)
