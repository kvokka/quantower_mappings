## Quantower symbols map creator

A dirty script for symbol mapping creation for [Quantower](https://www.quantower.com/).

This script is hardcoded for InteractiveBrokers and IQFeed.

Under the hood it grabs all the tickers from
[InteractiveBrokers](https://www1.interactivebrokers.com/en/index.php?f=2222&exch=amex&showcategories=STK&p=&cc=&limit=100&page=1) for NYSE Amex exchange and then convert it for Quantower backup format.

## Usage

. In Quantower -> Menu -> Backup Manager -> Backup settings
. Unzip settings archive
. Replace `symbolsMaps.xml` with `symbolsMaps.xml` file from this repo
. Zip all files back
. Restore backup settings in Quantower


## Re-generate xml

```ruby
git clone ...
cd ...
bundle install
bin/gen_mappings.rb
```