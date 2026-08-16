const { Client } = require("@elastic/elasticsearch");

const esClient = new Client({
  node: process.env.ELASTICSEARCH_URL || "http://localhost:9200"
});

async function testElasticsearchConnection() {
  const info = await esClient.info();
  return info;
}

module.exports = {
  esClient,
  testElasticsearchConnection
};