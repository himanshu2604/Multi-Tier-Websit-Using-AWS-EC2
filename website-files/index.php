<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ABC Company Registration</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
    <style>
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            font-family: 'Arial', sans-serif;
        }
        .container { padding-top: 50px; }
        .jumbotron {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 15px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
            backdrop-filter: blur(10px);
        }
        .server-info {
            background: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 20px;
            font-size: 12px;
            color: #6c757d;
        }
        .form-control {
            border-radius: 8px;
            border: 2px solid #e1e5e9;
            transition: all 0.3s ease;
        }
        .form-control:focus {
            border-color: #667eea;
            box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.25);
        }
        .btn-primary {
            background: linear-gradient(45deg, #667eea, #764ba2);
            border: none;
            border-radius: 8px;
            padding: 12px 30px;
            font-weight: 600;
            transition: transform 0.2s ease;
        }
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        }
    </style>
</head>
<body>
<div class="container">
    <div class="jumbotron">
        <div class="server-info">
            <strong>Server:</strong> <?php echo gethostname(); ?> | 
            <strong>Status:</strong> Running | 
            <strong>Load Balancer:</strong> Active |
            <strong>Time:</strong> <?php echo date('Y-m-d H:i:s T'); ?>
        </div>
        
        <h2 class="text-center" style="color: #667eea; margin-bottom: 30px;">
            🚀 ABC Company Registration
        </h2>
        
        <form method="post" class="form-horizontal">
            <div class="form-group">
                <label for="firstname" class="col-sm-3 control-label">Full Name:</label>
                <div class="col-sm-9">
                    <input type="text" class="form-control" name="firstname" 
                           placeholder="Enter your full name" required>
                </div>
            </div>
            
            <div class="form-group">
                <label for="email" class="col-sm-3 control-label">Email Address:</label>
                <div class="col-sm-9">
                    <input type="email" class="form-control" name="email" 
                           placeholder="Enter your email address" required>
                </div>
            </div>
            
            <div class="form-group">
                <div class="col-sm-offset-3 col-sm-9">
                    <button type="submit" class="btn btn-primary btn-lg">
                        📝 Submit Registration
                    </button>
                </div>
            </div>
        </form>
        
        <?php
        // Database connection and form processing
        if ($_SERVER['REQUEST_METHOD'] == 'POST') {
            $firstname = trim($_POST['firstname'] ?? '');
            $email = trim($_POST['email'] ?? '');
            
            // REPLACE WITH YOUR ACTUAL RDS ENDPOINT
            $servername = "capstone-project-db-1.cl8i6quocgwi.ap-south-1.rds.amazonaws.com";
            $username = "intel";
            $password = "intel123";
            $database = "intel";
            
            if (!empty($firstname) && !empty($email)) {
                try {
                    // Create connection with error handling
                    $conn = new mysqli($servername, $username, $password, $database);
                    
                    if ($conn->connect_error) {
                        throw new Exception("Database connection failed: " . $conn->connect_error);
                    }
                    
                    // Use prepared statement to prevent SQL injection
                    $stmt = $conn->prepare("INSERT INTO data (firstname, email) VALUES (?, ?)");
                    if (!$stmt) {
                        throw new Exception("Prepare failed: " . $conn->error);
                    }
                    
                    $stmt->bind_param("ss", $firstname, $email);
                    
                    if ($stmt->execute()) {
                        echo '<div class="alert alert-success" style="margin-top: 20px;">
                                <h4>✅ Success!</h4>
                                <p><strong>' . htmlspecialchars($firstname) . '</strong>, your registration has been saved successfully!</p>
                                <p><small>Email: ' . htmlspecialchars($email) . '</small></p>
                                <p><small>Processed by server: ' . gethostname() . '</small></p>
                              </div>';
                    } else {
                        throw new Exception("Execute failed: " . $stmt->error);
                    }
                    
                    $stmt->close();
                    $conn->close();
                    
                } catch (Exception $e) {
                    error_log("Database error: " . $e->getMessage());
                    echo '<div class="alert alert-warning" style="margin-top: 20px;">
                            <h4>⚠️ Database Temporarily Unavailable</h4>
                            <p>Your information could not be saved at this time. Please try again later.</p>
                            <p><small>Server: ' . gethostname() . ' | Time: ' . date('Y-m-d H:i:s') . '</small></p>
                          </div>';
                }
            } else {
                echo '<div class="alert alert-danger" style="margin-top: 20px;">
                        <h4>❌ Invalid Input</h4>
                        <p>Please fill in all required fields.</p>
                      </div>';
            }
        }
        ?>
        
        <div class="row" style="margin-top: 30px;">
            <div class="col-sm-6">
                <div class="panel panel-info">
                    <div class="panel-heading">
                        <h4>🔧 System Info</h4>
                    </div>
                    <div class="panel-body">
                        <small>
                            <strong>Instance:</strong> <?php echo gethostname(); ?><br>
                            <strong>PHP Version:</strong> <?php echo PHP_VERSION; ?><br>
                            <strong>MySQL Extension:</strong> <?php echo extension_loaded('mysqli') ? '✅ Available' : '❌ Missing'; ?><br>
                            <strong>Server Software:</strong> <?php echo $_SERVER['SERVER_SOFTWARE'] ?? 'Apache'; ?>
                        </small>
                    </div>
                </div>
            </div>
            <div class="col-sm-6">
                <div class="panel panel-success">
                    <div class="panel-heading">
                        <h4>✅ Features Active</h4>
                    </div>
                    <div class="panel-body">
                        <small>
                            ✓ Load Balancer: Active<br>
                            ✓ Auto Scaling: Active<br>
                            ✓ Database Integration: <?php echo extension_loaded('mysqli') ? 'Ready' : 'Error'; ?><br>
                            ✓ High Availability: Multi-AZ<br>
                            ✓ GitHub Deployment: Gist
                        </small>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<?php
// Health check endpoint for load balancer
if (isset($_GET['health']) || strpos($_SERVER['REQUEST_URI'], '/health') !== false) {
    http_response_code(200);
    echo "OK";
    exit;
}
?>

</body>
</html>