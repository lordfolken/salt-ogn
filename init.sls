---
include:
  - requisites.firewalld

add public zone:
  firewalld.present:
    - name: public
    - ports:
      - 8080/tcp
      - 8081/tcp

user ogn:
  user.present:
    - name: ogn
    - optional_groups:
      - plugdev

rtlsdr_dependencies:
  pkg.installed:
    - pkgs:
      - libpng-dev
      - libconfig-dev
      - libfftw3-dev
      - lynx
      - telnet 
      - ntp
      - ntpdate
      - procserv
      - nano
      - librtlsdr-dev

/etc/rtlsdr-ogn/site.conf:
  file.managed:
    - source: salt:///ogn/templates/site.conf.j2
    - makedirs: true
    - template: jinja
    - mode: '0644'
    - user: 'ogn'
    - group: 'ogn'
    - require: 
       - user ogn

/etc/rtlsdr-ogn.conf:
  file.managed:
    - source: salt:///ogn/templates/rtlsdr-ogn.conf.j2
    - makedirs: true
    - template: jinja
    - mode: '0644'
    - user: 'ogn'
    - group: 'ogn'
    - require: 
       - user ogn

/opt/rtlsdr-ogn-bin-arm64-latest.tgz:
  file.managed:
    - source: http://download.glidernet.org/arm64/rtlsdr-ogn-bin-arm64-latest.tgz
    - skip_verify: True 

extract_rtlsdr_ogn:
  archive.extracted:
    - name: /opt/
    - source: /opt/rtlsdr-ogn-bin-arm64-latest.tgz
    - archive_format: tar
    - tar_options: 'xzf'
    - watch:
      - file: /opt/rtlsdr-ogn-bin-arm64-latest.tgz

copy service to initd:
  file.managed:
    - name: /etc/init.d/rtlsdr-ogn
    - source: /opt/rtlsdr-ogn/rtlsdr-ogn
    - require:
      - extract_rtlsdr_ogn

{% for file in ['gsm_scan','ogn-rf','rtlsdr-ogn','ogn-decode'] %}
/opt/rtlsdr-ogn/{{ file }}:
  file.managed:
    - user: 'ogn'
    - group: 'ogn'
    - mode: '4755'
{% endfor %}

/opt/rtlsdr-ogn/gpu_dev:
  file.managed:
    - mknod: true
    - mode: '0666'
    - device_number: 'c 100 0' 
    - user: 'ogn'
    - group: 'ogn'

rtlsdr-ogn:
  service.running:
    - enable: true
    - watch:
      - /etc/rtlsdr-ogn.conf
      - /opt/rtlsdr-ogn/gpu_dev
      - copy service to initd:
