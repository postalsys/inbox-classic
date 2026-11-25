//! Settings sync: accounts, keys, the Address Book, rules, sign-in apps and settings kept the same on every computer
//! through a place the user owns (a synced folder or an S3 bucket). See `docs/sync-plan.md`.

pub mod apply;
pub mod backend;
pub mod crypt;
pub mod engine;
pub mod items;
pub mod manage;
pub mod run;
pub mod s3;
pub mod stamp;
pub mod vault;

#[cfg(test)]
mod tests;
