let express = require("express");
let app = new express();
app.set("view engine","ejs");
app.use(express.static('public'))

// set up database connection
const knex = require("knex")({
    client: "mysql2",
    // client: "mysql",
    connection: {
        // host:"movies-db.cluster-c8iotd3zbrrr.us-east-2.rds.amazonaws.com",
        host:"localhost",
        user: "root",
        password: "changeme",
        database:"movies",
        port: 3306,},});

app.get("/",(req,res) => {
    knex.select().from("movies")
    .then((result) => {
        console.log(result);
        res.render("index", {aMovieList: result});});});
app.listen(3000);
console.log("listening on port 3000")