let express = require("express");
let app = new express();
app.set("view engine","ejs");
app.use(express.static('public'))

// set up database connection
const knex = require("knex")({
    client: "mysql2",
    // client: "mysql",
    connection: {
        host:"http://adoptiondatabase-instance-1.caayec2cyrg1.us-east-1.rds.amazonaws.com/",
        // host:"localhost",
        user: "admin",
        password: "adminadmin",
        database:"adoptiondatabase",
        port: 3306,},});

app.get("/",(req,res) => {
    knex.select().from("adoptiondatabase")
    .then((result) => {
        console.log(result);
        res.render("index", {aAdoptionList: result});});});
app.listen(3000);
console.log("listening on port 3000")