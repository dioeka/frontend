<?php

namespace App\Http\Controllers\customer;

use App\Http\Controllers\Controller;
use App\Models\Keranjang;
use App\Models\Produk;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class KeranjangCustomerController extends Controller
{
    public function index()
    {
        $keranjang = Keranjang::join('produk','produk.id_produk','=','keranjang.id_produk')
        ->join('kategori','kategori.id_kategori','=','produk.id_kategori')
        ->select('keranjang.*','produk.nama_produk','produk.harga_produk','produk.foto_produk','kategori.nama_kategori')
        ->where('keranjang.id_user', Auth::user()->id)
        ->get();

        return view('customer.keranjang.keranjang', compact(['keranjang']));
    }

    public function storeApi(Request $request)
    {
        try {
            $request->validate([
                'id_user' => 'required',
                'id_produk' => 'required',
                'jumlah' => 'required|numeric|min:1'
            ]);

            $produk = Produk::find($request->id_produk);
            if (!$produk) {
                return response()->json(['message' => 'Produk tidak ditemukan'], 404);
            }

            if ($request->jumlah > $produk->stok) {
                return response()->json([
                    'message' => 'Jumlah melebihi stok yang tersedia'
                ], 400);
            }

            $keranjang = Keranjang::create([
                'id_user' => $request->id_user,
                'id_produk' => $request->id_produk,
                'quantity' => $request->jumlah
            ]);

            return response()->json([
                'message' => 'Berhasil menambahkan ke keranjang',
                'data' => $keranjang
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Gagal menambahkan ke keranjang: ' . $e->getMessage()
            ], 500);
        }
    }

    public function showApi($userId)
    {
        try {
            $keranjang = Keranjang::join('produk','produk.id_produk','=','keranjang.id_produk')
                ->select(
                    'keranjang.id_keranjang as id',
                    'produk.id_produk',
                    'produk.nama_produk',
                    'produk.harga_produk',
                    'produk.foto_produk',
                    'produk.berat',
                    'keranjang.quantity as jumlah'
                )
                ->where('keranjang.id_user', $userId)
                ->get();

            return response()->json($keranjang);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Gagal mengambil data keranjang: ' . $e->getMessage()
            ], 500);
        }
    }

    public function updateApi(Request $request, $id)
    {
        try {
            $request->validate([
                'jumlah' => 'required|numeric|min:1'
            ]);

            $keranjang = Keranjang::find($id);
            if (!$keranjang) {
                return response()->json(['message' => 'Item tidak ditemukan'], 404);
            }

            $produk = Produk::find($keranjang->id_produk);
            if ($request->jumlah > $produk->stok) {
                return response()->json([
                    'message' => 'Jumlah melebihi stok yang tersedia'
                ], 400);
            }

            $keranjang->update(['quantity' => $request->jumlah]);

            return response()->json([
                'message' => 'Berhasil mengupdate keranjang',
                'data' => $keranjang
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Gagal mengupdate keranjang: ' . $e->getMessage()
            ], 500);
        }
    }

    public function destroyApi($id)
    {
        try {
            $keranjang = Keranjang::find($id);
            if (!$keranjang) {
                return response()->json(['message' => 'Item tidak ditemukan'], 404);
            }

            $keranjang->delete();
            return response()->json(['message' => 'Berhasil menghapus item dari keranjang']);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Gagal menghapus item: ' . $e->getMessage()
            ], 500);
        }
    }

    public function store(Request $request)
    {
        $id = $request->id_produk;
        $produk = Produk::find($id);

        if ($request->quantity > $produk->stok) {
            return back()->with('gagal', 'Maaf Jumlah Pembelian Anda Melebihi Stok yang tersedia');
        }

        Keranjang::create([
            'id_user'=>Auth::user()->id,
            'id_produk'=>$request->id_produk,
            'quantity'=>$request->quantity
        ]);

        return to_route('customer.keranjang');
    }

    public function update(Request $request, $id)
    {
        $id_produk = $request->id_produk;
        $produk = Produk::find($id_produk);

        if ($request->quantity > $produk->stok) {
            return back()->with('gagal', 'Maaf Jumlah Pembelian Anda Melebihi Stok yang tersedia');
        }

        Keranjang::find($id)->update([
            'quantity'=>$request->quantity
        ]);

        return view('customer.keranjang.keranjang');
    }

    public function delete($id)
    {
        Keranjang::find($id)->delete();
        return back()->with('gagal', 'Berhasil Menghapus Produk Dari Keranjang');
    }
}
