# Supabase Queries Reference for Vendor App

## 🚀 **Best Queries for Your Implementation**

### **1. Vendor Profile Queries**

#### Get Vendor Profile with Statistics
```sql
-- Using the optimized function
SELECT * FROM get_vendor_profile_with_stats(auth.uid());

-- Manual query equivalent
SELECT 
    vp.*,
    COALESCE(svc_count.count, 0) as services_count,
    COALESCE(cat_count.count, 0) as categories_count,
    COALESCE(doc_count.count, 0) as documents_count
FROM vendor_profiles vp
LEFT JOIN (
    SELECT vendor_id, COUNT(*) as count 
    FROM services 
    GROUP BY vendor_id
) svc_count ON vp.id = svc_count.vendor_id
LEFT JOIN (
    SELECT vendor_id, COUNT(*) as count 
    FROM categories 
    GROUP BY vendor_id
) cat_count ON vp.id = cat_count.vendor_id
LEFT JOIN (
    SELECT vendor_id, COUNT(*) as count 
    FROM vendor_documents 
    GROUP BY vendor_id
) doc_count ON vp.id = doc_count.vendor_id
WHERE vp.user_id = auth.uid();
```

#### Update Vendor Profile
```sql
UPDATE vendor_profiles 
SET 
    business_name = $1,
    address = $2,
    category = $3,
    phone_number = $4,
    description = $5,
    updated_at = NOW()
WHERE user_id = auth.uid()
RETURNING *;
```

### **2. Category Management Queries**

#### Get Categories with Hierarchy
```sql
-- Using the optimized function
SELECT * FROM get_vendor_categories_hierarchy(vendor_uuid);

-- Manual recursive query
WITH RECURSIVE category_tree AS (
    -- Root categories
    SELECT 
        c.id, c.name, c.parent_id, c.created_at,
        0 as level, c.name as path
    FROM categories c
    WHERE c.vendor_id = $1 AND c.parent_id IS NULL
    
    UNION ALL
    
    -- Child categories
    SELECT 
        c.id, c.name, c.parent_id, c.created_at,
        ct.level + 1, ct.path || ' > ' || c.name
    FROM categories c
    INNER JOIN category_tree ct ON c.parent_id = ct.id
    WHERE c.vendor_id = $1
)
SELECT * FROM category_tree ORDER BY level, name;
```

#### Create Category
```sql
INSERT INTO categories (vendor_id, name, parent_id)
SELECT vp.id, $1, $2
FROM vendor_profiles vp
WHERE vp.user_id = auth.uid()
RETURNING *;
```

#### Delete Category (with safety check)
```sql
-- Check if category can be deleted
WITH category_check AS (
    SELECT 
        c.id,
        (SELECT COUNT(*) FROM services WHERE category_id = c.id) as services_count,
        (SELECT COUNT(*) FROM categories WHERE parent_id = c.id) as subcategories_count
    FROM categories c
    WHERE c.id = $1 AND c.vendor_id = (
        SELECT id FROM vendor_profiles WHERE user_id = auth.uid()
    )
)
DELETE FROM categories 
WHERE id = $1 
AND vendor_id = (SELECT id FROM vendor_profiles WHERE user_id = auth.uid())
AND EXISTS (
    SELECT 1 FROM category_check 
    WHERE services_count = 0 AND subcategories_count = 0
);
```

### **3. Service Management Queries**

#### Get Services with Category Info
```sql
-- Using the optimized function
SELECT * FROM get_vendor_services(vendor_uuid);

-- Manual query
SELECT 
    s.*,
    c.name as category_name,
    c.id as category_id
FROM services s
LEFT JOIN categories c ON s.category_id = c.id
WHERE s.vendor_id = (
    SELECT id FROM vendor_profiles WHERE user_id = auth.uid()
)
ORDER BY s.created_at DESC;
```

#### Search Services with Advanced Filters
```sql
-- Using the optimized search function
SELECT * FROM search_vendor_services(
    vendor_uuid := $1,
    search_term := $2,
    category_filter := $3,
    price_min := $4,
    price_max := $5,
    tags_filter := $6
);

-- Manual search query
SELECT 
    s.*,
    c.name as category_name,
    CASE 
        WHEN s.name ILIKE '%' || $1 || '%' THEN 3.0
        WHEN s.description ILIKE '%' || $1 || '%' THEN 2.0
        WHEN EXISTS(SELECT 1 FROM unnest(s.tags) tag WHERE tag ILIKE '%' || $1 || '%') THEN 1.5
        ELSE 0.0
    END as relevance_score
FROM services s
LEFT JOIN categories c ON s.category_id = c.id
WHERE s.vendor_id = (
    SELECT id FROM vendor_profiles WHERE user_id = auth.uid()
)
AND s.is_active = true
AND (
    s.name ILIKE '%' || $1 || '%'
    OR s.description ILIKE '%' || $1 || '%'
    OR EXISTS(SELECT 1 FROM unnest(s.tags) tag WHERE tag ILIKE '%' || $1 || '%')
)
AND ($2::UUID IS NULL OR s.category_id = $2)
AND ($3::DECIMAL IS NULL OR s.price >= $3)
AND ($4::DECIMAL IS NULL OR s.price <= $4)
AND (
    $5::TEXT[] IS NULL 
    OR $5 = '{}'::TEXT[]
    OR EXISTS(SELECT 1 FROM unnest(s.tags) tag WHERE tag = ANY($5))
)
ORDER BY relevance_score DESC, s.created_at DESC;
```

#### Create Service
```sql
INSERT INTO services (
    vendor_id, category_id, name, description, 
    price, tags, media_urls, is_active
)
SELECT 
    vp.id, $1, $2, $3, $4, $5, $6, $7
FROM vendor_profiles vp
WHERE vp.user_id = auth.uid()
RETURNING *;
```

#### Update Service
```sql
UPDATE services 
SET 
    name = $1,
    description = $2,
    price = $3,
    tags = $4,
    media_urls = $5,
    is_active = $6,
    updated_at = NOW()
WHERE id = $7 
AND vendor_id = (
    SELECT id FROM vendor_profiles WHERE user_id = auth.uid()
)
RETURNING *;
```

#### Toggle Service Status
```sql
UPDATE services 
SET is_active = NOT is_active, updated_at = NOW()
WHERE id = $1 
AND vendor_id = (
    SELECT id FROM vendor_profiles WHERE user_id = auth.uid()
)
RETURNING *;
```

### **4. Document Management Queries**

#### Get Documents by Type
```sql
SELECT 
    vd.*,
    vp.business_name
FROM vendor_documents vd
JOIN vendor_profiles vp ON vd.vendor_id = vp.id
WHERE vp.user_id = auth.uid()
AND ($1::TEXT IS NULL OR vd.document_type = $1)
ORDER BY vd.uploaded_at DESC;
```

#### Get Document Statistics
```sql
SELECT 
    document_type,
    COUNT(*) as count,
    MAX(uploaded_at) as last_uploaded
FROM vendor_documents vd
JOIN vendor_profiles vp ON vd.vendor_id = vp.id
WHERE vp.user_id = auth.uid()
GROUP BY document_type
ORDER BY count DESC;
```

### **5. Dashboard Analytics Queries**

#### Get Vendor Dashboard Stats
```sql
SELECT 
    -- Profile info
    vp.business_name,
    vp.category,
    vp.created_at as profile_created,
    
    -- Counts
    (SELECT COUNT(*) FROM services WHERE vendor_id = vp.id) as total_services,
    (SELECT COUNT(*) FROM services WHERE vendor_id = vp.id AND is_active = true) as active_services,
    (SELECT COUNT(*) FROM categories WHERE vendor_id = vp.id) as total_categories,
    (SELECT COUNT(*) FROM vendor_documents WHERE vendor_id = vp.id) as total_documents,
    
    -- Recent activity
    (SELECT MAX(created_at) FROM services WHERE vendor_id = vp.id) as last_service_added,
    (SELECT MAX(uploaded_at) FROM vendor_documents WHERE vendor_id = vp.id) as last_document_uploaded,
    
    -- Revenue estimate (if you add pricing)
    (SELECT COALESCE(SUM(price), 0) FROM services WHERE vendor_id = vp.id AND is_active = true) as total_service_value
    
FROM vendor_profiles vp
WHERE vp.user_id = auth.uid();
```

#### Get Category Performance
```sql
SELECT 
    c.name as category_name,
    COUNT(s.id) as services_count,
    COALESCE(AVG(s.price), 0) as avg_price,
    COUNT(CASE WHEN s.is_active THEN 1 END) as active_services,
    MAX(s.created_at) as last_service_added
FROM categories c
LEFT JOIN services s ON c.id = s.category_id
WHERE c.vendor_id = (
    SELECT id FROM vendor_profiles WHERE user_id = auth.uid()
)
GROUP BY c.id, c.name
ORDER BY services_count DESC;
```

### **6. Advanced Search and Filter Queries**

#### Multi-Criteria Service Search
```sql
SELECT 
    s.*,
    c.name as category_name,
    -- Full-text search relevance
    ts_rank(
        to_tsvector('english', s.name || ' ' || COALESCE(s.description, '')),
        plainto_tsquery('english', $1)
    ) as search_rank
FROM services s
LEFT JOIN categories c ON s.category_id = c.id
WHERE s.vendor_id = (
    SELECT id FROM vendor_profiles WHERE user_id = auth.uid()
)
AND s.is_active = true
AND (
    -- Text search
    to_tsvector('english', s.name || ' ' || COALESCE(s.description, '')) @@ plainto_tsquery('english', $1)
    -- OR simple ILIKE search
    OR s.name ILIKE '%' || $1 || '%'
    OR s.description ILIKE '%' || $1 || '%'
)
-- Category filter
AND ($2::UUID IS NULL OR s.category_id = $2)
-- Price range
AND ($3::DECIMAL IS NULL OR s.price >= $3)
AND ($4::DECIMAL IS NULL OR s.price <= $4)
-- Tags filter
AND (
    $5::TEXT[] IS NULL 
    OR $5 = '{}'::TEXT[]
    OR EXISTS(SELECT 1 FROM unnest(s.tags) tag WHERE tag = ANY($5))
)
-- Date range
AND ($6::DATE IS NULL OR s.created_at >= $6)
AND ($7::DATE IS NULL OR s.created_at <= $7)
ORDER BY search_rank DESC, s.created_at DESC
LIMIT $8 OFFSET $9;
```

### **7. Performance Optimization Queries**

#### Get Services with Pagination
```sql
SELECT 
    s.*,
    c.name as category_name,
    COUNT(*) OVER() as total_count
FROM services s
LEFT JOIN categories c ON s.category_id = c.id
WHERE s.vendor_id = (
    SELECT id FROM vendor_profiles WHERE user_id = auth.uid()
)
AND s.is_active = true
ORDER BY s.created_at DESC
LIMIT $1 OFFSET $2;
```

#### Get Categories with Service Counts (Efficient)
```sql
SELECT 
    c.*,
    COALESCE(svc_counts.service_count, 0) as service_count,
    COALESCE(sub_counts.subcategory_count, 0) as subcategory_count
FROM categories c
LEFT JOIN (
    SELECT category_id, COUNT(*) as service_count
    FROM services 
    GROUP BY category_id
) svc_counts ON c.id = svc_counts.category_id
LEFT JOIN (
    SELECT parent_id, COUNT(*) as subcategory_count
    FROM categories 
    GROUP BY parent_id
) sub_counts ON c.id = sub_counts.parent_id
WHERE c.vendor_id = (
    SELECT id FROM vendor_profiles WHERE user_id = auth.uid()
)
ORDER BY c.name;
```

### **8. Data Export Queries**

#### Export Vendor Data (CSV format)
```sql
-- This query can be used to export data for backup or analysis
SELECT 
    'vendor_profiles' as table_name,
    vp.id,
    vp.business_name,
    vp.category,
    vp.address,
    vp.created_at
FROM vendor_profiles vp
WHERE vp.user_id = auth.uid()

UNION ALL

SELECT 
    'services' as table_name,
    s.id,
    s.name,
    c.name as category,
    s.price::TEXT,
    s.created_at
FROM services s
LEFT JOIN categories c ON s.category_id = c.id
WHERE s.vendor_id = (
    SELECT id FROM vendor_profiles WHERE user_id = auth.uid()
)

UNION ALL

SELECT 
    'categories' as table_name,
    c.id,
    c.name,
    COALESCE(pc.name, 'Root') as parent_category,
    '' as price,
    c.created_at
FROM categories c
LEFT JOIN categories pc ON c.parent_id = pc.id
WHERE c.vendor_id = (
    SELECT id FROM vendor_profiles WHERE user_id = auth.uid()
)
ORDER BY table_name, created_at;
```

## 🔒 **Security Best Practices**

### **Always Use RLS Policies**
- All queries automatically respect Row Level Security
- Users can only access their own data
- No need to manually add `WHERE user_id = auth.uid()` in most cases

### **Use Parameterized Queries**
```sql
-- ✅ Good: Parameterized
SELECT * FROM services WHERE id = $1 AND vendor_id = $2;

-- ❌ Bad: String concatenation
SELECT * FROM services WHERE id = '$1' AND vendor_id = '$2';
```

### **Validate Input Data**
```sql
-- Always validate UUIDs
WHERE id = $1::UUID AND vendor_id = $2::UUID

-- Validate numeric ranges
WHERE price BETWEEN $1::DECIMAL AND $2::DECIMAL
```

## 📊 **Performance Tips**

### **Use Indexes Effectively**
- The schema includes optimized indexes for common queries
- Use `EXPLAIN ANALYZE` to check query performance
- Consider adding composite indexes for frequently used filter combinations

### **Limit Result Sets**
```sql
-- Always use LIMIT for potentially large result sets
SELECT * FROM services WHERE vendor_id = $1 LIMIT 100;

-- Use pagination for better UX
SELECT * FROM services WHERE vendor_id = $1 LIMIT $2 OFFSET $3;
```

### **Use Functions for Complex Queries**
- The provided functions are optimized and use `SECURITY DEFINER`
- They handle complex joins and calculations efficiently
- Consider using them instead of writing complex queries in your app

## 🚀 **Next Steps**

1. **Run the schema**: Execute `supabase_schema.sql` in your Supabase SQL Editor
2. **Test queries**: Use the SQL Editor to test these queries with your data
3. **Monitor performance**: Use Supabase's built-in query performance monitoring
4. **Optimize further**: Add custom indexes based on your specific usage patterns

These queries are production-ready and follow Supabase best practices for security, performance, and maintainability!
