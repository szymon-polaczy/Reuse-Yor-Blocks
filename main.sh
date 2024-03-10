gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /orgs/osomstudio/repos --paginate > repos.json 

cat repos.json | jq '.' > repos-pritified.json

jq ".[].full_name" -r repos-pritified.json > repo_urls.txt

cat repo_urls.txt | while read line || [[ -n $line ]];
do
	gh repo clone "$line"
done

#go through all of the folders
#	check if there is a web/app/themes/(juniper-theme|osom-theme)/blocks
#	go through those blocks and move them to the new site used for copies
#	change the name to block--project_slug
#	move the project acf-fields - change the block names to block--project_slug
#	remove the project folder as we don't need it
#we somehow have to then add those blocks on a page or multiple pages based on all projects
#when we added those blocks we have to fill in their fields so that we display something
#we will have issues with blocks that need some posts so we might have to create a list of projects pulled
#so that we can fix some posts or other things manually
