<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Pesanan;
use Carbon\Carbon;

class PesananAdminController extends Controller
{
    public function getPesananByStatus()
    {
        try {
            $pesananMasuk = Pesanan::where('status', 'pending')
                ->orderBy('created_at', 'desc')
                ->get();

            $pesananOnProgress = Pesanan::where('status', 'diproses')
                ->orderBy('created_at', 'desc')
                ->get();

            $pesananPengiriman = Pesanan::where('status', 'dikirim')
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'pesanan_masuk' => $pesananMasuk->map(function($pesanan) {
                    return [
                        'id' => $pesanan->id,
                        'nama_pelanggan' => $pesanan->user->name ?? 'Pelanggan',
                        'total_harga' => $pesanan->total_harga,
                        'tanggal' => Carbon::parse($pesanan->created_at)->format('d M Y H:i'),
                        'status' => $pesanan->status,
                        'items' => $pesanan->items->count()
                    ];
                }),
                'pesanan_on_progress' => $pesananOnProgress->map(function($pesanan) {
                    return [
                        'id' => $pesanan->id,
                        'nama_pelanggan' => $pesanan->user->name ?? 'Pelanggan',
                        'total_harga' => $pesanan->total_harga,
                        'tanggal' => Carbon::parse($pesanan->created_at)->format('d M Y H:i'),
                        'status' => $pesanan->status,
                        'items' => $pesanan->items->count()
                    ];
                }),
                'pesanan_pengiriman' => $pesananPengiriman->map(function($pesanan) {
                    return [
                        'id' => $pesanan->id,
                        'nama_pelanggan' => $pesanan->user->name ?? 'Pelanggan',
                        'total_harga' => $pesanan->total_harga,
                        'tanggal' => Carbon::parse($pesanan->created_at)->format('d M Y H:i'),
                        'status' => $pesanan->status,
                        'items' => $pesanan->items->count()
                    ];
                })
            ]);
        } catch (\Exception $e) {
            \Log::error('Error getting orders: ' . $e->getMessage());
            return response()->json([
                'message' => 'Gagal mengambil data pesanan: ' . $e->getMessage()
            ], 500);
        }
    }

    public function updateStatus(Request $request, $id)
    {
        try {
            $pesanan = Pesanan::findOrFail($id);
            $pesanan->status = $request->status;
            $pesanan->save();

            return response()->json([
                'message' => 'Status pesanan berhasil diperbarui',
                'pesanan' => $pesanan
            ]);
        } catch (\Exception $e) {
            \Log::error('Error updating order status: ' . $e->getMessage());
            return response()->json([
                'message' => 'Gagal memperbarui status pesanan: ' . $e->getMessage()
            ], 500);
        }
    }
}
