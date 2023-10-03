module "keypairs-module" {
  source          = "../keypairs"
  key-pairs-names = ["ansible-key", "bootstrap-key"]
}
