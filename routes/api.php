<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Customer\KeranjangCustomerController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::get('/getDashboardData', [App\Http\Controllers\Admin\DashboardAdminController::class, 'getDashboardData']);
Route::get('/getPesananByStatus', [App\Http\Controllers\Admin\PesananAdminController::class, 'getPesananByStatus']);
Route::post('/updatePesananStatus/{id}', [App\Http\Controllers\Admin\PesananAdminController::class, 'updateStatus']);
Route::get('/getProduk', [App\Http\Controllers\HomeController::class, 'getProduk']);
Route::post('/login', [App\Http\Controllers\Auth\LoginController::class, 'loginApi']);
Route::post('/register', [App\Http\Controllers\Auth\RegisterController::class, 'registerApi']);

// Cart Routes
Route::post('/keranjang', [KeranjangCustomerController::class, 'storeApi']);
Route::get('/keranjang/{id}', [KeranjangCustomerController::class, 'showApi']);
Route::put('/keranjang/{id}', [KeranjangCustomerController::class, 'updateApi']);
Route::delete('/keranjang/{id}', [KeranjangCustomerController::class, 'destroyApi']);

// Other existing routes...
Route::post('/storeApi', [App\Http\Controllers\Admin\ProdukAdminController::class, 'storeApi']);
Route::get('/kategoriApi', [App\Http\Controllers\Admin\ProdukAdminController::class, 'kategoriApi']);
Route::get('/editApi/{id}', [App\Http\Controllers\Admin\ProdukAdminController::class, 'editApi']);
Route::put('/updateApi/{id}', [App\Http\Controllers\Admin\ProdukAdminController::class, 'updateApi']);
Route::delete('/deleteApi/{id}', [App\Http\Controllers\Admin\ProdukAdminController::class, 'destroyApi']);
Route::get('/kategori', function() {
    return response()->json(App\Models\KategoriModel::all());
});

Route::get('/getUser', [App\Http\Controllers\Admin\ProdukAdminController::class, 'userApi']);
//register

Route::post('/auth/register', [App\Http\Controllers\Auth\RegisterController::class, 'register']);
Route::put('/customer/fotoApi/{id}', [App\Http\Controllers\Customer\ProfileCustomerController::class, 'update_fotoApi']);

//kategori
//Route::get('/kategoriGetApi', [App\Http\Controllers\Admin\KategoriAdminController::class, 'getKategori']);
Route::get('/kategori', [App\Http\Controllers\Admin\KategoriAdminController::class, 'getAllKategori']);
Route::post('/kategoriStoreApi', [App\Http\Controllers\Admin\KategoriAdminController::class, 'storeApi']);
Route::get('/kategoriEditApi/{id}', [App\Http\Controllers\Admin\KategoriAdminController::class, 'editApi']);
Route::put('/kategoriUpdateApi/{id}', [App\Http\Controllers\Admin\KategoriAdminController::class, 'updateApi']);
Route::delete('/kategoriDeleteApi/{id}', [App\Http\Controllers\Admin\KategoriAdminController::class, 'destroyApi']);

// User Management Routes
Route::get('/users', [App\Http\Controllers\Admin\UserController::class, 'index']);
Route::get('/users/{id}', [App\Http\Controllers\Admin\UserController::class, 'show']);
Route::post('/users', [App\Http\Controllers\Admin\UserController::class, 'store']);
Route::put('/users/{id}', [App\Http\Controllers\Admin\UserController::class, 'update']);
Route::delete('/users/{id}', [App\Http\Controllers\Admin\UserController::class, 'destroy']);

// Customer Management Routes
Route::get('/customers', [App\Http\Controllers\Admin\CustomerController::class, 'index']);
Route::get('/customers/{id}', [App\Http\Controllers\Admin\CustomerController::class, 'show']);
Route::post('/customers', [App\Http\Controllers\Admin\CustomerController::class, 'store']);
Route::put('/customers/{id}', [App\Http\Controllers\Admin\CustomerController::class, 'update']);
Route::delete('/customers/{id}', [App\Http\Controllers\Admin\CustomerController::class, 'destroy']);

// Admin Management Routes
Route::get('/admins', [App\Http\Controllers\Admin\AdminController::class, 'index']);
Route::get('/admins/{id}', [App\Http\Controllers\Admin\AdminController::class, 'show']);
Route::post('/admins', [App\Http\Controllers\Admin\AdminController::class, 'store']);
Route::put('/admins/{id}', [App\Http\Controllers\Admin\AdminController::class, 'update']);
Route::delete('/admins/{id}', [App\Http\Controllers\Admin\AdminController::class, 'destroy']);

// Checkout and Payment Routes
Route::get('/rekening', [App\Http\Controllers\Admin\RekeningAdminController::class, 'getRekening']);
Route::post('/checkout', [App\Http\Controllers\Customer\CheckoutCustomerController::class, 'checkout']);
Route::post('/upload-payment/{id}', [App\Http\Controllers\Customer\CheckoutCustomerController::class, 'uploadPayment']);

// Address Routes
Route::get('/provinsi', [App\Http\Controllers\Customer\AlamatUserController::class, 'get_provinsi']);
Route::get('/kota/{provinsi_id}', [App\Http\Controllers\Customer\AlamatUserController::class, 'get_city']);
Route::post('/saveAlamat/{userId}', [App\Http\Controllers\Customer\AlamatUserController::class, 'saveAlamat']);

// Admin Profile Routes
Route::get('/admin/profile/{id}', [App\Http\Controllers\Admin\ProfileAdminController::class, 'getProfileApi']);
Route::post('/admin/profile/update-foto/{id}', [App\Http\Controllers\Admin\ProfileAdminController::class, 'update_fotoApi']);
Route::post('/admin/profile/update-data/{id}', [App\Http\Controllers\Admin\ProfileAdminController::class, 'update_dataApi']);
Route::post('/admin/profile/update-password/{id}', [App\Http\Controllers\Admin\ProfileAdminController::class, 'update_passwordApi']);