# GitHub Pages Hosting Guide
## Deploying Studio Documentation to GitHub Pages

This guide provides comprehensive instructions for hosting the Studio Platform documentation on GitHub Pages using MkDocs.

## 🎯 Why GitHub Pages?

### **Benefits**
- **Free Hosting** - No cost for public repositories
- **Custom Domain** - Support for `doc.cybergaar.com`
- **Automatic HTTPS** - Free SSL certificates
- **Global CDN** - Fast content delivery worldwide
- **Version Control** - Documentation versioned with code
- **CI/CD Integration** - Automatic builds on changes
- **High Availability** - 99.9% uptime guarantee

### **Limitations**
- **Storage** - 1GB free storage limit
- **Bandwidth** - 100GB free bandwidth per month
- **Build Time** - 10 minutes build timeout
- **Private Repos** - Requires GitHub Pro for private repos

## 🚀 Setup Options

### **Option 1: GitHub Actions (Recommended)**
Automated deployment with continuous integration.

### **Option 2: Manual Deployment**
Using `mkdocs gh-deploy` command.

### **Option 3: Third-Party CI/CD**
Using external CI/CD services.

## 📋 Prerequisites

### **Requirements**
- GitHub account
- Git installed locally
- MkDocs installed: `pip install mkdocs`
- Repository created on GitHub

### **Repository Structure**
```
studio/
├── .github/
│   └── workflows/
│       └── deploy-docs.yml
├── docs/
│   ├── docs/
│   │   ├── CNAME
│   │   └── ...
│   ├── mkdocs.yml
│   ├── requirements.txt
│   └── ...
└── README.md
```

## 🔧 Option 1: GitHub Actions (Recommended)

### **Step 1: Enable GitHub Pages**

1. Go to your repository on GitHub
2. Click **Settings** tab
3. Scroll down to **GitHub Pages** section
4. Under **Build and deployment**, select **GitHub Actions**
5. Click **Save**

### **Step 2: Create Workflow**

The workflow file `.github/workflows/deploy-docs.yml` has been created with:

```yaml
name: Deploy Documentation

on:
  push:
    branches: [ main, develop ]
    paths: [ 'docs/**' ]
  pull_request:
    branches: [ main ]
    paths: [ 'docs/**' ]

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v4
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    - name: Install dependencies
      run: |
        cd docs
        pip install -r requirements.txt
    - name: Build documentation
      run: |
        cd docs
        mkdocs build --clean
    - name: Setup Pages
      uses: actions/configure-pages@v3
    - name: Upload artifact
      uses: actions/upload-pages-artifact@v2
      with:
        path: ./docs/site

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    steps:
    - name: Deploy to GitHub Pages
      id: deployment
      uses: actions/deploy-pages@v2
```

### **Step 3: Configure Custom Domain**

#### **Create CNAME File**
```bash
# Create CNAME file in docs/docs/
echo "doc.cybergaar.com" > docs/docs/CNAME
git add docs/docs/CNAME
git commit -m "Add CNAME for custom domain"
git push
```

#### **Configure DNS**
1. Go to your domain registrar
2. Create a CNAME record:
   - **Name**: `doc` (or `@` for root domain)
   - **Type**: `CNAME`
   - **Value**: `username.github.io`
   - **TTL**: `3600` (1 hour)

#### **Update GitHub Pages Settings**
1. Go to repository **Settings** → **Pages**
2. Under **Custom domain**, enter `doc.cybergaar.com`
3. Click **Save**
4. Verify DNS configuration

## 🔧 Option 2: Manual Deployment

### **Step 1: Install MkDocs**
```bash
pip install mkdocs
```

### **Step 2: Build Documentation**
```bash
cd docs
mkdocs build --clean
```

### **Step 3: Deploy Using gh-deploy**
```bash
# Use the provided script
./scripts/deploy-github-pages.sh

# Or manually
cd docs
mkdocs gh-deploy --force
```

### **Step 4: Enable GitHub Pages**
1. Go to repository **Settings** → **Pages**
2. Under **Source**, select **Deploy from a branch**
3. Choose **gh-pages** branch
4. Select **/(root)** folder
5. Click **Save**

## 🔧 Option 3: Manual Git Deployment

### **Step 1: Build Documentation**
```bash
cd docs
mkdocs build --clean
```

### **Step 2: Create gh-pages Branch**
```bash
# Create orphan branch
git checkout --orphan gh-pages

# Remove all files
git rm -rf .

# Add nojekyll file
touch .nojekyll
git add .nojekyll
git commit -m "Initial gh-pages setup"

# Copy built site
cp -r site/* .
git add .
git commit -m "Deploy documentation"

# Push to GitHub
git push origin gh-pages --force
```

### **Step 3: Switch Back to Main Branch**
```bash
git checkout main
```

## 🌐 Custom Domain Configuration

### **DNS Settings**

#### **CNAME Record (Recommended)**
```
Type: CNAME
Name: doc
Value: username.github.io
TTL: 3600
```

#### **A Record (Alternative)**
```
Type: A
Name: doc
Value: 185.199.108.153
TTL: 3600

Type: A
Name: doc
Value: 185.199.108.154
TTL: 3600

Type: A
Name: doc
Value: 185.199.109.153
TTL: 3600

Type: A
Name: doc
Value: 185.199.109.154
TTL: 3600
```

### **HTTPS Configuration**
GitHub Pages automatically provides HTTPS for custom domains once DNS is properly configured.

## 🔍 Verification and Testing

### **Check Deployment Status**

#### **GitHub Actions**
1. Go to repository **Actions** tab
2. Click on the **Deploy Documentation** workflow
3. Check if all steps completed successfully

#### **Manual Deployment**
```bash
# Check if gh-pages branch exists
git branch -a | grep gh-pages

# Check if site is built
ls -la docs/site/
```

### **Test Website**
```bash
# Check default GitHub Pages URL
curl https://username.github.io/studio/

# Check custom domain
curl https://doc.cybergaar.com
```

## 🚨 Troubleshooting

### **Common Issues**

#### **Build Fails**
```bash
# Check MkDocs configuration
cd docs
mkdocs build --verbose

# Check for missing dependencies
pip install -r requirements.txt
```

#### **Deployment Fails**
```bash
# Check git remote
git remote -v

# Check permissions
git config --list | grep user

# Force push
git push origin gh-pages --force
```

#### **Custom Domain Not Working**
```bash
# Check DNS propagation
nslookup doc.cybergaar.com
dig doc.cybergaar.com

# Check CNAME file
cat docs/docs/CNAME

# Check GitHub Pages settings
# Go to Settings > Pages > Custom domain
```

#### **404 Errors**
```bash
# Check if files exist in gh-pages branch
git checkout gh-pages
ls -la
git checkout main

# Check if index.html exists
ls docs/site/index.html
```

#### **HTTPS Issues**
1. Wait 24 hours after DNS configuration
2. Check DNS propagation
3. Verify CNAME record points to `username.github.io`
4. Check GitHub Pages settings

### **Debugging Steps**

#### **Local Testing**
```bash
# Serve locally
cd docs
mkdocs serve --dev-addr=0.0.0.0:8000

# Build locally
mkdocs build --clean --strict

# Check configuration
mkdocs config validate
```

#### **GitHub Actions Debugging**
```yaml
# Add debug steps to workflow
- name: Debug environment
  run: |
    pwd
    ls -la
    python --version
    pip list

- name: Debug build
  run: |
    cd docs
    mkdocs build --verbose --strict
```

## 📊 Performance Optimization

### **Asset Optimization**

#### **Image Optimization**
```bash
# Add to workflow
- name: Optimize images
  run: |
    find site -name "*.png" -exec pngquant --quality=65-80 --output {} --force {} \;
    find site -name "*.jpg" -o -name "*.jpeg" -exec jpegoptim --max=80 --strip-all {} \;
```

#### **CSS/JS Minification**
```bash
# Add to workflow
- name: Minify assets
  run: |
    find site -name "*.css" -exec cleancss --output {} {} \;
    find site -name "*.js" -exec terser {} --output {} --compress --mangle {} \;
```

### **Caching Configuration**

#### **GitHub Pages Caching**
GitHub Pages automatically caches static assets for 1 hour.

#### **Browser Caching**
```yaml
# Add to mkdocs.yml
extra:
  cache:
    enabled: true
    ttl: 3600
```

## 🔄 Maintenance

### **Regular Tasks**

#### **Weekly**
- Check deployment status
- Monitor performance metrics
- Review GitHub Actions logs

#### **Monthly**
- Update dependencies
- Optimize images
- Check SSL certificate expiry

#### **Quarterly**
- Review analytics
- Update documentation structure
- Check for broken links

### **Monitoring**

#### **GitHub Pages Status**
- Check [GitHub Status](https://www.githubstatus.com/)
- Monitor deployment success rate
- Track build times

#### **Performance Monitoring**
```bash
# Add to workflow
- name: Performance check
  run: |
    curl -I https://doc.cybergaar.com
    curl -w "@curl-format.txt" -o /dev/null -s https://doc.cybergaar.com
```

## 📈 Analytics and SEO

### **Google Analytics**
```yaml
# Add to mkdocs.yml
extra:
  analytics:
    provider: google
    property: G-XXXXXXXXXX
```

### **SEO Optimization**
```yaml
# Add to mkdocs.yml
plugins:
  - meta
  - sitemap
  - robots
```

### **Sitemap Generation**
```yaml
# Add to mkdocs.yml
plugins:
  - sitemap:
      url_scheme: https
```

## 🔒 Security

### **HTTPS Enforcement**
GitHub Pages automatically redirects HTTP to HTTPS.

### **Content Security Policy**
```yaml
# Add to mkdocs.yml
extra:
  security:
    csp:
      default-src: "'self'"
      script-src: "'self' 'unsafe-inline'"
      style-src: "'self' 'unsafe-inline'"
```

### **Access Control**
- **Private Repositories**: Requires GitHub Pro
- **IP Whitelisting**: Not available on GitHub Pages
- **Authentication**: Use GitHub authentication

## 📋 Final Checklist

### **Before Going Live**
- [ ] GitHub Actions workflow configured
- [ ] Custom domain DNS configured
- [ ] CNAME file created
- [ ] HTTPS certificate verified
- [ ] All links tested
- [ ] Performance optimized
- [ ] Analytics configured
- [ ] SEO settings applied

### **After Deployment**
- [ ] Test all pages load correctly
- [ ] Verify HTTPS works
- [ ] Check mobile responsiveness
- [ ] Test search functionality
- [ ] Validate navigation
- [ ] Monitor performance
- [ ] Set up alerts for build failures

---

## 🎉 Success!

Your Studio Platform documentation is now hosted on GitHub Pages at `https://doc.cybergaar.com` with automatic builds, HTTPS, and global CDN delivery.

### **Next Steps**
1. Monitor deployment success rate
2. Set up analytics tracking
3. Regularly update documentation
4. Optimize for performance
5. Monitor SSL certificate expiry
