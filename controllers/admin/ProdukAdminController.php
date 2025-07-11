<?php

namespace App\Http\Controllers\admin;

use App\Http\Controllers\Controller;
use App\Models\Kategori;
use App\Models\Produk;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use App\Models\User;

class ProdukAdminController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index()
    {
        $produk = Produk::join('kategori','kategori.id_kategori','=','produk.id_kategori')
        ->orderBy('nama_produk', 'asc')
        ->get();
        return view('admin.produk.produk', compact(['produk']));
    }

    /**
     * Show the form for creating a new resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function create()
    {
        $kategori = Kategori::orderBy('nama_kategori', 'asc')->get();
        return view('admin.produk.produk_create', compact(['kategori']));
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {  
        $request->validate([
            'nama_produk'=>'required|unique:produk,nama_produk',
            'stok_produk'=>'required',
            'berat_produk'=>'required',
            'harga_produk'=>'required',
            'deskripsi_produk'=>'required',
            'img1'=>'required',
        ]);

        $harga = preg_replace("/[^0-9]/", "", $request->harga_produk);

        if ($request->hasFile('img1')) {
            $foto_produk= $request->file('img1')->getClientOriginalName();
            $request->img1->move(public_path('produk'), $foto_produk);
        }

        Produk::create([
            'nama_produk'=>$request->nama_produk,
            'id_kategori'=>$request->kategori_produk,
            'berat'=>$request->berat_produk,
            'stok'=>$request->stok_produk,
            'harga_produk'=>$harga,
            'deskripsi_produk'=>$request->deskripsi_produk,
            'foto_produk'=>$foto_produk,
        ]);

        return to_route('produk.index')->with('success','Berhasil Menambahkan Produk Baru');
    }

    /**
     * Display the specified resource.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function show($id)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function edit($id)
    {
        $produk = Produk::find($id);
        $kategori = Kategori::orderBy('nama_kategori', 'asc')->get();
        return view('admin.produk.produk_edit', compact(['kategori','produk']));
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, $id)
    {
        $request->validate([
            'nama_produk'=>'required',
            'stok_produk'=>'required',
            'berat_produk'=>'required',
            'harga_produk'=>'required',
            'deskripsi_produk'=>'required',
        ]);

        $harga = preg_replace("/[^0-9]/", "", $request->harga_produk);

        if ($request->hasFile('img1')) {
            $foto_produk= $request->file('img1')->getClientOriginalName();
            $request->img1->move(public_path('produk'), $foto_produk);

        }else{
            $foto_produk = $request->foto_lama;
        }

        Produk::find($id)->update([
            'nama_produk'=>$request->nama_produk,
            'id_kategori'=>$request->kategori_produk,
            'berat'=>$request->berat_produk,
            'stok'=>$request->stok_produk,
            'harga_produk'=>$harga,
            'deskripsi_produk'=>$request->deskripsi_produk,
            'foto_produk'=>$foto_produk,
        ]);

        return to_route('produk.index')->with('success','Berhasil Memperbaharui Produk');


    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function destroy($id)
    {
        //
        Produk::find($id)->delete();
        return to_route('produk.index')->with('delete','Berhasil Menghapus Produk');
    }

    public function kategoriApi()
    {
        $kategori = Kategori::orderBy('nama_kategori', 'asc')->get();
        return response()->json($kategori);
    }

    public function storeApi(Request $request)
    {
       //return response()->json(($request->img1));
        $request->validate([
            'nama_produk'=>'required|unique:produk,nama_produk',
            'stok_produk'=>'required',
            'berat_produk'=>'required',
            'harga_produk'=>'required',
            'deskripsi_produk'=>'required',
            'img1'=>'required',
        ]);

        $harga = preg_replace("/[^0-9]/", "", $request->harga_produk);

        if ($request->hasFile('img1')) {
            $foto_produk= $request->file('img1')->getClientOriginalName();
            $request->img1->move(public_path('produk'), $foto_produk);

        }
        /*if(!empty($request->img1)){
            $file = base64_decode($request->img1);
            //$folderName = 'produk';
            $safeName = str_random(10).'.'.'png';
            $destinationPath = public_path('produk');
            file_put_contents(public_path('produk').$safeName, $file);

            //file_put_contents(public_path().'produk'.$imageName, base64_decode($image));
            //Storage::disk('produk')->put($imageName, base64_decode($image));
        }*/

        $produk=Produk::create([
            'nama_produk'=>$request->nama_produk,
            'id_kategori'=>$request->kategori_produk,
            'berat'=>$request->berat_produk,
            'stok'=>$request->stok_produk,
            'harga_produk'=>$harga,
            'deskripsi_produk'=>$request->deskripsi_produk,
            'foto_produk'=>$foto_produk,
        ]);

        return response()->json($produk);
    }
    public function editApi($id)
    {
        try {
            $produk = Produk::join('kategori', 'kategori.id_kategori', '=', 'produk.id_kategori')
                ->select('produk.*', 'kategori.nama_kategori')
                ->where('produk.id_produk', $id)
                ->first();

            if (!$produk) {
                return response()->json([
                    'success' => false,
                    'message' => 'Produk tidak ditemukan',
                ], 404);
            }

            // Verify if image exists
            $imagePath = public_path('produk/' . $produk->foto_produk);
            $produk->foto_exists = file_exists($imagePath);

            return response()->json([
                'success' => true,
                'user' => $produk
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error: ' . $e->getMessage()
            ], 500);
        }
    }

    public function updateApi(Request $request, $id)
    {
        try {
            $request->validate([
                'nama_produk' => 'required',
                'kategori_produk' => 'required|exists:kategori,id_kategori',
                'stok_produk' => 'required|numeric|min:0',
                'berat_produk' => 'required',
                'harga_produk' => 'required|numeric|min:0',
                'deskripsi_produk' => 'required',
            ]);

            $produk = Produk::find($id);
            if (!$produk) {
                return response()->json([
                    'success' => false,
                    'message' => 'Produk tidak ditemukan'
                ], 404);
            }

            $harga = preg_replace("/[^0-9]/", "", $request->harga_produk);
            $foto_produk = $request->foto_lama;

            if ($request->hasFile('img1')) {
                $file = $request->file('img1');
                $foto_produk = time() . '_' . $file->getClientOriginalName();
                
                // Create directory if it doesn't exist
                $uploadPath = public_path('produk');
                if (!file_exists($uploadPath)) {
                    mkdir($uploadPath, 0777, true);
                }

                // Delete old image if exists
                if ($produk->foto_produk && file_exists(public_path('produk/' . $produk->foto_produk))) {
                    unlink(public_path('produk/' . $produk->foto_produk));
                }

                // Save new image
                $file->move($uploadPath, $foto_produk);
            }

            $produk->update([
                'nama_produk' => $request->nama_produk,
                'id_kategori' => $request->kategori_produk,
                'berat' => $request->berat_produk,
                'stok' => $request->stok_produk,
                'harga_produk' => $harga,
                'deskripsi_produk' => $request->deskripsi_produk,
                'foto_produk' => $foto_produk,
            ]);

            // Verify if new image exists
            $imagePath = public_path('produk/' . $foto_produk);
            $imageExists = file_exists($imagePath);

            return response()->json([
                'success' => true,
                'message' => 'Produk berhasil diperbarui',
                'data' => $produk,
                'image_exists' => $imageExists,
                'image_path' => 'produk/' . $foto_produk
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error: ' . $e->getMessage()
            ], 500);
        }
    }
    public function destroyApi($id)
    {
        //
        Produk::find($id)->delete();
        return response()->json("Berhasil di Hapus");
    }
    public function userApi()
    {
        $kategori = User::orderBy('name', 'asc')->get();
        return response()->json($kategori);
    }
}
