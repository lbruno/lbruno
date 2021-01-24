# Serving static files from Hetzner

1. Chose to do so due to GDPR reasons: writing a privacy notice for GH pages was becoming too bothersome.
2. Chose their cheapest "cloud" server:
    - It's still similar to a VM that I have to manage
    - Gives me some welcome flexibility, I can SSH into and run `wget --mirror` in there.

## Setting up the CX11 "cloud" server

1.  SSH:

    Important to listen on `0.0.0.0:22` while one checks that port `:30622` is indeed usable.
    
    - `ListenAddress 0.0.0.0:30622`
    - `PasswordAuthentication no`
    - `PermitRootLogin without-password`

2.  Installed packages:

    - python3-certbot-nginx
    - python3-certbot-dns-gandi
    - certbot
    - nginx-light
    - dnsutils
    - rblcheck
    
2.  Certbot:

    - Installed `python3-certbot-dns-gandi` for using DNS-v01 ownership checks to get the new cert.
        - Wildly useful if the DNS label is currently pointing at the "production" hosting service, which stops HTTP-v01 from working.
    - `python3-certbot-nginx` does a piss-poor job of meddling with the `sites-available/default` config-part.
    - Privilege separation:
      1. Added a "certbot" team in the Gandi admin console, with limited permissions: change DNS records across the org.
      2. Created a separate account, and added it to the "certbot" team.
      3. generated an API key for this other account
      4. created a gandi.ini file with:
      
         `certbot_plugin_gandi:dns_api_key=<that API key>`
      
      5. Ran certbot in DNS mode:
      
         `certbot -a certbot-plugin-gandi:dns --certbot-plugin-gandi:dns-credentials gandi.ini -d blog.lbruno.org`

3.  NGINX:

    - removed the default `/var/www/html` directory
    - created a `/var/www/empty` directory
    - mirrored my lbruno.github.io website to `/var/www/blog.lbruno.org`
    - created a set-up that serves a single named vhost `blog.lbruno.org` from that path.
    - added some data privacy settings (see below)

## GDPR and privacy

Because by default nginx logs like a Yank, needed to change the logging settings and their retention:

- IP addresses are logged to `access.log` but have their final octet masked: `192.168.3.32` becomes `192.168.3.0`.
- `access.log` is kept for at most 1 day.
- `error.log` has been disabled

These decisions and the rationale behind them needs to be covered by a DPIA(!):

- The nginx software allows a) custom logging formats, and b) creating new variables based off others, with some small changes.
  - This allows me to create a logging format that logs an IP address that is masked: only 24bits of address (out of 32) remain.
    - the remaining bits are less specific, they represent somewhat large swathes of the users' ISP installed client-base.
    - I then overrode the format used to log `access.log` for the single named-vhost in the nginx configuration
- one can't use the same trick for `error.log`, so I've outright disabled that logging.
- I don't see why I'd have a need for more than 1d of `access.log`:
  - At most, I expect to use this for operational reasons: see how much traffic in aggregate I get, and from which bits of the world.
    - Need again to explain the 24bits granularity.
  - this is a separate bit of configuration
  - should also implement controls to ensure these two configurations are kept over the lifetime of the VM.

## Mirroring

TL;DR:

```
wget --mirror --convert-links --page-requisites --adjust-extension --directory-prefix /var/www/blog.lbruno.org --no-host-directories lbruno.github.io{,/.well-known/keybase.txt}
````
 
I'm currently using GitHub pages as my editor + Jekyll builder combo. Hence the fancy `wget --mirror` script
that creates `/var/www/blog.lbruno.org`. Has the advantage of stable authoritative storage for the future, as well.

Problem is that GH has GDPR implications, and I was getting tired of exploring those while writing (what I
thought it should be) a simple privacy notice. Hence the whole jigmarole of configuring a tiny server at Hetzner,
just to serve static files from inside Europe. Finland, to be more precise.

## References

- https://chriswiegman.com/2019/09/anonymizing-nginx-logs/
- https://gurjitmehta.wordpress.com/2017/04/04/mirroring-websites-using-wget-httrack/
- https://gdpr.eu/article-12-how-controllers-should-provide-personal-data-to-the-subject/ and following articles.
  - Understanding the GDPR isn't easy work, but it's worth it.
