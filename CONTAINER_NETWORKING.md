# Container Networking Guide for Ansible-NAS

## Problem
Currently, containers reference each other using the host VM's IP address (192.168.12.100), which makes the setup non-portable and requires manual updates when migrating to different servers.

## Solution: Custom Docker Network with Container Name Resolution

### Implementation Steps

#### 1. Create Custom Docker Network
All containers will join a custom bridge network called `ansible-nas` where they can resolve each other by container name.

```bash
# Create the network (already done)
docker network create --driver bridge ansible-nas
```

#### 2. Update Container Configurations
Each role needs to be updated to:
- Join the `ansible-nas` network
- Use container names instead of IP addresses

### Container Name Reference Table

Once all containers are on the same network, you can use these hostnames internally:

| Service | Container Name | Internal URL | External URL |
|---------|---------------|--------------|--------------|
| Plex | plex | http://plex:32400 | https://plex.1815.space |
| Radarr | radarr | http://radarr:7878 | https://radarr.1815.space |
| Sonarr | sonarr | http://sonarr:8989 | https://sonarr.1815.space |
| NZBGet | nzbget | http://nzbget:6789 | https://nzbget.1815.space |
| rTorrent | rtorrent | http://rtorrent:8080 | https://rtorrent.1815.space |
| Traefik | traefik | http://traefik:8080 | http://192.168.12.100:8083 |
| Homepage | homepage | http://homepage:3000 | https://home.1815.space |
| Unmanic | unmanic | http://unmanic:8888 | https://unmanic.1815.space |
| Boxarr | boxarr | http://boxarr:8888 | https://boxarr.1815.space |
| Spotizerr | spotizerr | http://spotizerr:7171 | https://spotizerr.1815.space |
| Memos | memos | http://memos:5230 | https://docs.1815.space |
| Listmonk | listmonk | http://listmonk:9000 | https://listmonk.1815.space |
| Nullboard | nullboard | http://nullboard:80 | https://nullboard.1815.space |

### Example Role Update

To update a role to use the custom network, add the `networks` section:

```yaml
- name: Create Container
  community.docker.docker_container:
    name: "{{ app_container_name }}"
    image: "{{ app_image }}"
    networks:
      - name: ansible-nas
    # ... rest of configuration
```

### Configuration Updates Needed

#### 1. Homepage Configuration
Update `/home/mk/docker/homepage/services.yaml`:
```yaml
- Media:
    - Radarr:
        widget:
          type: radarr
          url: "http://radarr:7878"  # Instead of http://192.168.12.100:7878
          key: "API_KEY"
```

#### 2. Radarr/Sonarr Download Client Settings
In Radarr/Sonarr web UI:
- NZBGet: Use `nzbget` as hostname instead of `192.168.12.100`
- rTorrent: Use `rtorrent` as hostname instead of `192.168.12.100`

#### 3. Container Environment Variables
Some containers might have environment variables with IPs that need updating.

### Migration Benefits

1. **Portability**: When moving to a new server, no IP updates needed
2. **DNS Resolution**: Containers resolve each other by name
3. **Isolation**: Custom network provides better isolation than default bridge
4. **Simplified Configuration**: Use meaningful names instead of IPs

### Alternative Solutions

#### Option 1: Use Docker Host Network Mode
```yaml
network_mode: host
```
- Pros: Containers can use `localhost`
- Cons: No network isolation, port conflicts possible

#### Option 2: Use Extra Hosts
```yaml
extra_hosts:
  - "radarr:192.168.12.100"
  - "sonarr:192.168.12.100"
```
- Pros: Works without custom network
- Cons: Still uses IPs, just aliased

#### Option 3: Use Docker Compose
Create a single `docker-compose.yml` for all services:
- Pros: Automatic DNS resolution, single configuration file
- Cons: Major refactor from Ansible approach

### Recommended Approach

1. **Short Term**: Add all containers to `ansible-nas` network
2. **Configuration**: Update each service to use container names
3. **Testing**: Verify inter-container communication
4. **Documentation**: Update CLAUDE.md with new networking setup

### Testing Connectivity

```bash
# Test from one container to another
docker exec radarr ping nzbget
docker exec radarr curl http://nzbget:6789

# View network details
docker network inspect ansible-nas

# List containers on network
docker network inspect ansible-nas | jq '.[0].Containers'
```

### Rollback Plan

If issues occur, containers will still work with IP addresses even when on custom network, so you can migrate gradually.

---
**Note**: This change requires updating all container configurations and redeploying them. Plan for a maintenance window.