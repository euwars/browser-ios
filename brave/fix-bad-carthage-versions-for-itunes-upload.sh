grep -lrF '3.0b' Carthage | xargs sed -i '' 's/3.0b/3.0/g'
grep -lrF '-beta.3' Carthage | xargs sed -i '' 's/-beta\.3//g'
