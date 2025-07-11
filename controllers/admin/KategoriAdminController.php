<?php

namespace App\Http\Controllers\admin;

use App\Http\Controllers\Controller;
use App\Models\Kategori;
use Illuminate\Http\Request;

class KategoriAdminController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index()
    {
        $kategori = Kategori::latest()->paginate(5);
        return view('admin.kategori.kategori', compact(['kategori']));
    }
    
    /**
     * Show the form for creating a new resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function create()
    {
        //
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
            'kategori'=>'required|unique:kategori,nama_kategori',
        ]);

        Kategori::create([
            'nama_kategori'=>$request->kategori,
            'deskripsi_kategori'=>$request->deskripsi_kategori
        ]);

        return back()->with('success','Berhasil Menambahkan Kategori Baru');
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
        $edit = Kategori::find($id);
        $kategori = Kategori::latest()->paginate(5);
        return view('admin.kategori.kategori_edit', compact(['kategori','edit']));

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
            'kategori'=>'required',
        ]);

        Kategori::find($id)->update([
            'nama_kategori'=>$request->kategori,
            'deskripsi_kategori'=>$request->deskripsi_kategori
        ]);

        return to_route('kategori.index')->with('success','Berhasil Memperbaharui Kategori');
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function destroy($id)
    {
        Kategori::find($id)->delete();

        return to_route('kategori.index')->with('delete', 'Berhasil Menghapus Kategori');
    }

    public function getAllKategori()
    {
        $kategori = Kategori::orderBy('nama_kategori', 'asc')->get();
        return response()->json($kategori);
    }

    public function storeApi(Request $request)
    {
        //dd($request);
        $request->validate([
            'nama_kategori'=>'required|unique:kategori,nama_kategori',
        ]);

        $kategori=Kategori::create([
            'nama_kategori'=>$request->nama_kategori,
            'deskripsi_kategori'=>$request->deskripsi_kategori
        ]);

        return response()->json($kategori);
    }
    public function editApi($id)
    {
        //dd($id);
        $edit = Kategori::find($id);
        //$kategori = Kategori::orderBy('nama_kategori', 'asc')->get();
        return response()->json(['kategori'  => $edit]);

    }
    public function updateApi(Request $request, $id)
    {
        //dd($request);
        $request->validate([
            'nama_kategori'=>'required',
        ]);
       
        $kategori=Kategori::find($id)->update([
            'nama_kategori'=>$request->nama_kategori,
            'deskripsi_kategori'=>$request->deskripsi_kategori
        ]);

        return response()->json("Data Berhasil di Update");
    }
    public function destroyApi($id)
    {
        Kategori::find($id)->delete();

        return response()->json("Berhasil di Hapus");
    }
}
